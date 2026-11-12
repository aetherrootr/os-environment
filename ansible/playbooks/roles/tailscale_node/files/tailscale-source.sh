#!/bin/bash
# Use manually assigned source identities for Tailscale transport only.
set -euo pipefail

CONFIG=/etc/default/tailscale-source
NAT=TS_SOURCE_NAT
GUARD=TS_SOURCE_IPV6
COMMENT=tailscale-source
OWN=0x80000/0xff0000
FORWARDED=0x40000/0xff0000

topology() {
    # This is a root-maintained shell configuration, like other /etc/default files.
    source "$CONFIG"
    : "${SOURCE_IPV4:?Set SOURCE_IPV4 in $CONFIG}" "${SOURCE_IPV6:?Set SOURCE_IPV6 in $CONFIG}"
    local route addresses preferred
    route=$(ip -j -4 route show table main default | jq -ec '
        [.[] | select(.dev != "tailscale0")] | min_by(.metric // 0) | select(.dev != null)')
    interface=$(jq -er '.dev' <<< "$route")
    [[ $interface =~ ^[a-zA-Z0-9_.:-]+$ ]]
    addresses=$(ip -j address show dev "$interface" | jq -ec '.[0].addr_info')
    # Route lookup validates and canonicalizes both addresses without changing routes.
    source4=$(ip -j -4 route get "$SOURCE_IPV4" | jq -er '.[0].dst')
    source6=$(ip -j -6 route get "$SOURCE_IPV6" | jq -er '.[0].dst')
    if ! jq -e --arg v4 "$source4" --arg v6 "$source6" '
        map(select(.tentative != true and .dadfailed != true)) |
        any(.local == $v4) and any(.local == $v6)' <<< "$addresses" > /dev/null; then
        echo "Both manually configured source addresses must already exist on $interface" >&2
        return 1
    fi
    preferred=$(jq -r '.prefsrc // ""' <<< "$route")
    primary4=$(jq -er --arg source "$source4" --arg preferred "$preferred" '
        [.[] | select(.family == "inet" and .local != $source and .tentative != true) | .local] |
        if index($preferred) then $preferred else .[0] // empty end' <<< "$addresses")
    # Public unicast IPv6 uses 2000::/3; ignore ULA, deprecated and tentative addresses.
    primary6=$(jq -r --arg source "$source6" '
        [.[] | select(.family == "inet6" and .scope == "global" and .local != $source
          and (.local | test("^[23]")) and .tentative != true and .dadfailed != true
          and .deprecated != true and .preferred_life_time != 0) | .local] | .[0] // ""' <<< "$addresses")
    # Include directly connected prefixes learned through RA as well as kernel routes.
    prefixes6=$(ip -j -6 route show table main dev "$interface" |
        jq -r '[.[] | select(.gateway == null) | .dst // "" | select(test("^[23]"))] | unique[]')
}

nat_rules() {
    local family=$1 primary dedicated network protocol
    local -a excluded
    if [[ $family == 4 ]]; then
        primary=$primary4 dedicated=$source4
        excluded=(0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
                  172.16.0.0/12 192.168.0.0/16 198.18.0.0/16 224.0.0.0/3)
    else
        primary=$primary6 dedicated=$source6
        excluded=(::1/128 fc00::/7 fe80::/10 ff00::/8 2001:2::/64 fdfe:dcba:9876::/64)
        while IFS= read -r network; do
            [[ -z $network ]] || excluded+=("$network")
        done <<< "$prefixes6"
    fi
    # Before destination exclusions: fake-IP and LAN forwarding use the ordinary identity too.
    if [[ -n $primary ]]; then
        printf -- '-A %s -m mark --mark %s -j SNAT --to-source %s\n' "$NAT" "$FORWARDED" "$primary"
    fi
    for network in "${excluded[@]}"; do
        printf -- '-A %s -d %s -j RETURN\n' "$NAT" "$network"
    done
    for protocol in udp tcp; do
        printf -- '-A %s -p %s -m mark --mark %s -m addrtype --src-type LOCAL -j SNAT --to-source %s\n' \
            "$NAT" "$protocol" "$OWN" "$dedicated"
    done
}

restore_rules() {
    local binary=$1 payload=$2
    "$binary-restore" --test --noflush <<< "$payload"
    "$binary-restore" --wait 5 --noflush <<< "$payload"
}

ensure_chain() {
    local binary=$1 table=$2 chain=$3 rules=$4 current
    current=$("$binary" -w 5 -t "$table" -S "$chain" 2>/dev/null || true)
    current=$(sed -n "/^-A $chain /p" <<< "$current")
    if [[ $current != "$rules" ]]; then
        restore_rules "$binary" "$(printf '*%s\n:%s - [0:0]\n-F %s\n%s\nCOMMIT\n' "$table" "$chain" "$chain" "$rules")"
    fi
}

ensure_jump() {
    local binary=$1 table=$2 parent=$3 chain=$4 current payload
    shift 4
    local -a rule=("$@" -m comment --comment "$COMMENT" -j "$chain")
    current=$("$binary" -w 5 -t "$table" -S "$parent" | sed -n '/^-A /p')
    current=${current//\"/}
    [[ ${current%%$'\n'*} != "-A $parent ${rule[*]}" ]] || return 0
    payload="*$table"$'\n'
    if "$binary" -w 5 -t "$table" -C "$parent" "${rule[@]}" 2>/dev/null; then
        payload+="-D $parent ${rule[*]}"$'\n'
    fi
    payload+="-I $parent 1 ${rule[*]}"$'\nCOMMIT'
    restore_rules "$binary" "$payload"
}

write_sysctl() {
    local key=$1 value=$2
    [[ $(< "/proc/sys/$key") == "$value" ]] || printf '%s\n' "$value" > "/proc/sys/$key"
}

apply() {
    topology
    write_sysctl "net/ipv6/conf/$interface/accept_ra" 2
    write_sysctl net/ipv4/ip_forward 1
    write_sysctl net/ipv6/conf/all/forwarding 1
    # Mangle runs before filter, so Tailscale's own ACCEPT cannot bypass this guard.
    local verdict=DROP binary family rules
    [[ -z $primary6 ]] || verdict=RETURN
    ensure_chain ip6tables mangle "$GUARD" "-A $GUARD -j $verdict"
    ensure_jump ip6tables mangle FORWARD "$GUARD" -i tailscale0 -o "$interface"
    for family in 4 6; do
        binary=iptables
        [[ $family == 4 ]] || binary=ip6tables
        rules=$(nat_rules "$family")
        ensure_chain "$binary" nat "$NAT" "$rules"
        ensure_jump "$binary" nat POSTROUTING "$NAT" -o "$interface"
    done
}

remove_chain() {
    local binary=$1 table=$2 parent=$3 chain=$4 line current
    local -a rule
    current=$("$binary" -w 5 -t "$table" -S "$parent")
    while IFS= read -r line; do
        line=${line//\"/}
        if [[ $line == "-A $parent "*" --comment $COMMENT -j $chain" ]]; then
            read -r -a rule <<< "$line"
            "$binary" -w 5 -t "$table" -D "${rule[@]:1}"
        fi
    done <<< "$current"
    if "$binary" -w 5 -t "$table" -S "$chain" >/dev/null 2>&1; then
        "$binary" -w 5 -t "$table" -F "$chain"
        "$binary" -w 5 -t "$table" -X "$chain"
    fi
}

main() {
    case ${1:-} in
        check)
            topology
            jq -n --arg interface "$interface" --arg source4 "$source4" --arg source6 "$source6" \
                --arg primary4 "$primary4" --arg primary6 "$primary6" \
                '{interface: $interface, source4: $source4, source6: $source6,
                  primary4: $primary4, primary6: (if $primary6 == "" then null else $primary6 end)}'
            ;;
        apply|remove)
            exec 9>/run/tailscale-source.lock
            flock -x 9
            if [[ $1 == apply ]]; then
                apply
            else
                # Removal also works after manual source addresses or config have been removed.
                remove_chain ip6tables mangle FORWARD "$GUARD"
                remove_chain iptables nat POSTROUTING "$NAT"
                remove_chain ip6tables nat POSTROUTING "$NAT"
            fi
            ;;
        watch)
            while :; do
                # A separate process preserves errexit: a failed command must stop this apply.
                bash "${BASH_SOURCE[0]}" apply || echo 'Source policy refresh failed; retrying in 30 seconds.' >&2
                sleep 30
            done
            ;;
        *) echo "Usage: $0 check|apply|watch|remove" >&2; return 1 ;;
    esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
