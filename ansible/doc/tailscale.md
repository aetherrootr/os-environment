# Deploy Tailscale Exit Nodes

Run commands from the repository's `ansible/` directory. Install Ansible first
and confirm SSH access as `aether` using your existing key. Have the node's
sudo password ready.

## 1. Configure the inventory

Edit [inventories/tailscale/hosts.yaml](../inventories/tailscale/hosts.yaml).
Use domain names for node connections.

- `tailscale_login_server`: backup nodes use our Headscale server; the other nodes use the official Tailscale service.
- `tailscale_source_policy_enabled`: use `false` for ordinary exit nodes. The current four nodes enable a dedicated DHCP identity with `true`.
- `tailscale_subnet_routes`: subnets to advertise from this node. Omit to preserve existing routes, or use `[]` to clear them.

## 2. Install

Start with one node:

```sh
ANSIBLE_ASK_PASS=false ansible-playbook \
  -i inventories/tailscale/hosts.yaml playbooks/tailscale_nodes.yaml
```

Installation prepares the packages, configuration, and startup script.
The maintainer handles authentication and initial startup.
Deploy separately if their sudo passwords differ.

## 3. Request the additional lease

Connect to the node:

```sh
ssh -t aether@node-name.corp.aetherrootr.com
```

Run on the node:

```sh
~/start-tailscale-node.sh
```

Enter the sudo password. With source policy enabled and no saved configuration,
confirm the additional DHCP identity. The startup script creates `ts-source`
with a stable MAC, obtains a lease, and prints the IP and MAC. Startup pauses here.
The node must use systemd-networkd for this mode.
Initial preparation reloads networkd and may briefly interrupt existing connections.

On the router, manually reserve the printed IPv4 address for the printed MAC.
The node continues using DHCP; leased addresses are never converted to local
static addresses. IPv6 is learned through the router's RA/DHCPv6 configuration.

## 4. Start and verify

Run `~/start-tailscale-node.sh` again. Complete the login link if authentication
is required. If the control server does not match, check the inventory and the
node's existing account before proceeding.

Run `tailscale status` and approve the exit-node and subnet routes in the
corresponding control server. Select the exit node on a client and test web
and LAN access before repeating these steps for the remaining nodes.

Source-address separation takes effect on the node. For Tailscale transport to
use the router's real WAN egress, manually configure a router/OpenClash bypass
for only the dedicated source IPv4/IPv6 shown by the script, matching the
dedicated MAC where supported. Keep ordinary/business source addresses under
the router's proxy rules. A static DHCP reservation only stabilizes the IPv4
address; it does not configure this bypass. Verify IPv4, IPv6, and WebRTC egress
from a client using this exit node after the router rules are ready.
