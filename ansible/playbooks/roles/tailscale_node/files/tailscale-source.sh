#!/bin/bash
# Use dedicated source identities for Tailscale transport only.
set -euo pipefail

CONFIG=${TAILSCALE_SOURCE_CONFIG:-/etc/default/tailscale-source}
NAT=TS_SOURCE_NAT
GUARD=TS_SOURCE_IPV6
COMMENT=tailscale-source
OWN=0x80000/0xff0000
FORWARDED=0x40000/0xff0000
DHCP_INTERFACE=ts-source
DHCP_TABLE=2053
DHCP_PRIORITY=5100
OUTPUT_GUARD=TS_SOURCE_OUTPUT

dhcp_rule_matches() {
    jq -e --argjson table "$DHCP_TABLE" --argjson priority "$DHCP_PRIORITY" '
        length == 1 and (.[0].table | tostring) == ($table | tostring) and .[0].priority == $priority and
        .[0].fwmark == "0x80000" and .[0].fwmask == "0xff0000"' >/dev/null
}

prepare_dhcp() (
    : "${SOURCE_MAC:?Set SOURCE_MAC in $CONFIG}"
    [[ $SOURCE_MAC =~ ^02(:[0-9a-f]{2}){5}$ ]]
    systemctl is-active --quiet systemd-networkd.service || {
        echo 'DHCP source mode requires systemd-networkd to be running.' >&2; exit 1;
    }
    [[ -f /etc/systemd/network/05-tailscale-source.network ]]
    route=$(ip -j -4 route show table main default | jq -ec '
        [.[] | select(.dev != null and .dev != "tailscale0" and .dev != "ts-source")] |
        min_by(.metric // 0) | select(.dev != null)')
    parent=$(jq -er '.dev' <<< "$route")
    parent_index=$(ip -j link show dev "$parent" | jq -er '.[0].ifindex')
    if ip -d -j link show dev "$DHCP_INTERFACE" > /dev/null 2>&1; then
        ip -d -j link show dev "$DHCP_INTERFACE" | jq -e --arg mac "$SOURCE_MAC" \
            --arg parent_name "$parent" --argjson parent "$parent_index" '
            .[0] | .address == $mac and (.link_index == $parent or .link == $parent_name) and
            .linkinfo.info_kind == "macvlan" and .linkinfo.info_data.mode == "bridge"' >/dev/null || {
            echo 'ts-source already exists with a different identity or parent; left unchanged.' >&2; exit 1;
        }
    fi
    # Refuse to reuse routing resources belonging to another application.
    for family in -4 -6; do
        rules=$(ip -j "$family" rule show | jq -c --argjson priority "$DHCP_PRIORITY" '[.[] | select(.priority == $priority)]')
        if [[ $rules != '[]' ]]; then
            dhcp_rule_matches <<< "$rules" || {
                echo "Policy rule priority $DHCP_PRIORITY is already in use." >&2; exit 1;
            }
        fi
        rules=$(ip -j "$family" rule show | jq -c --arg table "$DHCP_TABLE" '.[] | select((.table | tostring) == $table)')
        if [[ -n $rules ]]; then
            jq -s '.' <<< "$rules" | dhcp_rule_matches || {
                echo "Routing table $DHCP_TABLE is referenced by another policy rule." >&2; exit 1;
            }
        fi
        if ! routes=$(ip -j "$family" route show table "$DHCP_TABLE" 2>/dev/null); then
            routes='[]'
        fi
        jq -e --arg dev "$DHCP_INTERFACE" 'all(.[]; .dev == $dev or
            (.type == "unreachable" and .metric == 42760))' <<< "$routes" >/dev/null || {
            echo "Routing table $DHCP_TABLE is already in use." >&2; exit 1;
        }
    done
    created=0
    old_arp=$(< "/proc/sys/net/ipv4/conf/$parent/arp_ignore")
    trap 'status=$?; if ((status != 0 && created == 1)); then
        ip link delete dev "$DHCP_INTERFACE" || true
        printf "%s\n" "$old_arp" > "/proc/sys/net/ipv4/conf/$parent/arp_ignore"
      fi; exit "$status"' EXIT
    # Prevent the parent and child from answering ARP for each others addresses.
    if ! ip link show dev "$DHCP_INTERFACE" >/dev/null 2>&1; then
        ip link add link "$parent" name "$DHCP_INTERFACE" address "$SOURCE_MAC" type macvlan mode bridge
        created=1
    fi
    if ((old_arp < 1)); then write_sysctl "net/ipv4/conf/$parent/arp_ignore" 1; fi
    write_sysctl "net/ipv4/conf/$DHCP_INTERFACE/arp_ignore" 1
    write_sysctl "net/ipv4/conf/$DHCP_INTERFACE/arp_announce" 2
    write_sysctl "net/ipv4/conf/$DHCP_INTERFACE/rp_filter" 2
    ip link set dev "$DHCP_INTERFACE" up
    if [[ $created == 1 ]]; then
        networkctl reload
        networkctl reconfigure "$DHCP_INTERFACE"
    fi
    for attempt in {1..60}; do
        if ip -j -4 address show dev "$DHCP_INTERFACE" | jq -e '
            any(.[].addr_info[]?; .scope == "global" and .dynamic == true and .valid_life_time != 0)' >/dev/null; then
            leased4=$(ip -j -4 address show dev "$DHCP_INTERFACE" | jq -er '
                [.[].addr_info[]? | select(.scope == "global" and .dynamic == true and .valid_life_time != 0) | .local][0]')
            if ip -j -4 address show dev "$parent" | jq -e --arg lease "$leased4" \
                'any(.[].addr_info[]?; .local == $lease)' >/dev/null; then
                echo 'DHCP returned the ordinary interface address; refusing to reuse it.' >&2
                exit 1
            fi
            # DHCP and RA routes must remain isolated from ordinary traffic.
            for family in -4 -6; do
                ip -j "$family" route show table main dev "$DHCP_INTERFACE" | jq -e \
                    'all(.[]; .dst == "fe80::/64")' >/dev/null || {
                    echo 'The DHCP interface added a main-table route; refusing to continue.' >&2; exit 1;
                }
            done
            exit 0
        fi
        sleep 1
    done
    echo 'No additional DHCPv4 lease received on ts-source within 60 seconds.' >&2
    exit 1
)

prepare_addresses() (
    source "$CONFIG"
    if [[ ${SOURCE_METHOD:-static} == dhcp ]]; then
        prepare_dhcp
        exit
    fi
    [[ ${MANAGE_SOURCE_ADDRESSES:-0} == 1 ]] || exit 0
    : "${SOURCE_IPV4:?Set SOURCE_IPV4 in $CONFIG}" "${SOURCE_IPV6:?Set SOURCE_IPV6 in $CONFIG}"
    route=$(ip -j -4 route show table main default | jq -ec '
        [.[] | select(.dev != null and .dev != "tailscale0")] |
        min_by(.metric // 0) | select(.dev != null)')
    interface=$(jq -er '.dev' <<< "$route")
    [[ $interface =~ ^[a-zA-Z0-9_.:-]+$ ]]
    source4=$(ip -j -4 route get "$SOURCE_IPV4" | jq -er '.[0].dst')
    source6=$(ip -j -6 address show dev "$interface" to "$SOURCE_IPV6/128" |
        jq -r --arg value "$SOURCE_IPV6" '[.[].addr_info[]?][0].local // $value')
    addresses=$(ip -j address show dev "$interface" | jq -ec '.[0].addr_info')
    added4=0 added6=0
    trap 'status=$?; if ((status != 0)); then
        [[ $added6 == 0 ]] || ip -6 address del "$source6/128" dev "$interface" || true
        [[ $added4 == 0 ]] || ip -4 address del "$source4/32" dev "$interface" || true
      fi; exit "$status"' EXIT
    if ! jq -e --arg address "$source4" 'any(.local == $address)' <<< "$addresses" >/dev/null; then
        # A dedicated IPv4 must be on the directly connected LAN.
        ip -j -4 route get "$source4" | jq -e --arg dev "$interface" '
            .[0] | .dev == $dev and .gateway == null and (.type // "unicast") == "unicast"' >/dev/null
        arping -q -D -I "$interface" -c 3 -w 3 "$source4" || {
            echo "IPv4 conflict check failed for $source4; choose another unused address." >&2
            exit 1
        }
        ip -4 address add "$source4/32" dev "$interface"
        added4=1
    fi
    if ! jq -e --arg address "$source6" 'any(.local == $address)' <<< "$addresses" >/dev/null; then
        ip -6 address add "$source6/128" dev "$interface" preferred_lft 0
        added6=1
    fi
    # Wait for IPv6 duplicate-address detection, including boolean and flag-list formats.
    for attempt in {1..20}; do
        address=$(ip -j -6 address show dev "$interface" to "$source6/128" |
            jq -ec '[.[].addr_info[]?][0] // empty')
        source6=$(jq -er '.local' <<< "$address")
        if jq -e '.dadfailed == true or ((.flags // []) | index("dadfailed") != null)' <<< "$address" >/dev/null; then
            echo "IPv6 duplicate address detected: $source6" >&2
            exit 1
        fi
        if jq -e '.tentative != true and ((.flags // []) | index("tentative") == null)' <<< "$address" >/dev/null; then
            exit 0
        fi
        sleep 0.25
    done
    echo "IPv6 duplicate-address detection did not finish for $source6" >&2
    exit 1
)

topology() {
    # This is a root-maintained shell configuration, like other /etc/default files.
    source "$CONFIG"
    local route addresses preferred
    route=$(ip -j -4 route show table main default | jq -ec '
        [.[] | select(.dev != "tailscale0")] | min_by(.metric // 0) | select(.dev != null)')
    interface=$(jq -er '.dev' <<< "$route")
    [[ $interface =~ ^[a-zA-Z0-9_.:-]+$ ]]
    addresses=$(ip -j address show dev "$interface" | jq -ec '.[0].addr_info')
    transport=$interface
    if [[ ${SOURCE_METHOD:-static} == dhcp ]]; then
        transport=$DHCP_INTERFACE
        local leased
        leased=$(ip -j address show dev "$transport" | jq -ec '.[0].addr_info')
        source4=$(jq -er '[.[] | select(.family == "inet" and .scope == "global"
            and .dynamic == true and .valid_life_time != 0) | .local][0] // empty' <<< "$leased")
        source6=$(jq -r '[.[] | select(.family == "inet6" and .scope == "global"
            and .preferred_life_time != 0 and .tentative != true and .dadfailed != true
            and .temporary != true) | .local] | .[0] // ""' <<< "$leased")
    else
        : "${SOURCE_IPV4:?Set SOURCE_IPV4 in $CONFIG}" "${SOURCE_IPV6:?Set SOURCE_IPV6 in $CONFIG}"
        # Route lookup validates and canonicalizes both addresses without changing routes.
        source4=$(ip -j -4 route get "$SOURCE_IPV4" | jq -er '.[0].dst')
        source6=$(ip -j -6 route get "$SOURCE_IPV6" | jq -er '.[0].dst')
        if ! jq -e --arg v4 "$source4" --arg v6 "$source6" '
            map(select(.tentative != true and .dadfailed != true)) |
            any(.local == $v4) and any(.local == $v6)' <<< "$addresses" > /dev/null; then
            echo "Both configured source addresses must exist on $interface" >&2
            return 1
        fi
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
        [[ ${SOURCE_METHOD:-static} != dhcp ]] || break
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
    prepare_addresses
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
    if [[ ${SOURCE_METHOD:-static} == dhcp ]]; then
        # Install the guard before enabling the dedicated routing policy.
        # No SNAT of leased addresses: kernel source selection follows lease changes.
        for binary in iptables ip6tables; do
            rules=$(printf -- '-A %s -o lo -j RETURN\n-A %s ! -o %s -j DROP\n-A %s -m addrtype ! --src-type LOCAL --limit-iface-out -j DROP\n' \
                "$OUTPUT_GUARD" "$OUTPUT_GUARD" "$transport" "$OUTPUT_GUARD")
            ensure_chain "$binary" mangle "$OUTPUT_GUARD" "$rules"
            ensure_jump "$binary" mangle OUTPUT "$OUTPUT_GUARD" -m mark --mark "$OWN"
        done
        for family in -4 -6; do
            rules=$(ip -j "$family" rule show | jq -c --argjson priority "$DHCP_PRIORITY" '[.[] | select(.priority == $priority)]')
            if [[ $rules == '[]' ]]; then
                ip "$family" rule add priority "$DHCP_PRIORITY" fwmark "$OWN" table "$DHCP_TABLE"
            else
                dhcp_rule_matches <<< "$rules" || {
                    echo "Policy rule priority $DHCP_PRIORITY is already in use." >&2; return 1;
                }
            fi
        done
    fi
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
            jq -n --arg interface "$interface" --arg transport "$transport" --arg mac "${SOURCE_MAC:-}" --arg source4 "$source4" --arg source6 "$source6" \
                --arg primary4 "$primary4" --arg primary6 "$primary6" \
                '{interface: $interface, transport: $transport, mac: $mac, source4: $source4, source6: $source6,
                  primary4: $primary4, primary6: (if $primary6 == "" then null else $primary6 end)}'
            ;;
        prepare|apply|remove)
            exec 9>/run/tailscale-source.lock
            flock -x 9
            if [[ $1 == prepare ]]; then
                prepare_addresses
            elif [[ $1 == apply ]]; then
                apply
            else
                # Removal also works after manual source addresses or config have been removed.
                remove_chain ip6tables mangle FORWARD "$GUARD"
                remove_chain iptables nat POSTROUTING "$NAT"
                remove_chain ip6tables nat POSTROUTING "$NAT"
                for binary in iptables ip6tables; do
                    remove_chain "$binary" mangle OUTPUT "$OUTPUT_GUARD"
                done
                for family in -4 -6; do
                    rules=$(ip -j "$family" rule show | jq -c --argjson priority "$DHCP_PRIORITY" '[.[] | select(.priority == $priority)]')
                    if dhcp_rule_matches <<< "$rules"; then
                        ip "$family" rule del priority "$DHCP_PRIORITY" fwmark "$OWN" table "$DHCP_TABLE"
                    fi
                done
            fi
            ;;
        watch)
            while :; do
                # A separate process preserves errexit: a failed command must stop this apply.
                bash "${BASH_SOURCE[0]}" apply || echo 'Source policy refresh failed; retrying in 30 seconds.' >&2
                sleep 30
            done
            ;;
        *) echo "Usage: $0 check|prepare|apply|watch|remove" >&2; return 1 ;;
    esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
