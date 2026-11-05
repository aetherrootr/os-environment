# GL-MT6000

Update DNS on `192.168.8.1` through `playbooks/router_dns.yaml`.
The general router entry point is `playbooks/router_gl_mt6000.yaml`.
Run commands from the repository's `ansible/` directory with Ansible and `tk`
installed. For SSH key authentication, set `ANSIBLE_ASK_PASS=false`.

## Configure DNS

Edit the appropriate file:

- `dns/nodes.libsonnet`: server addresses.
- `dns/applications.libsonnet`: application domains.
- `dns/storages.libsonnet`: storage endpoints.

Use `generateDNSRecord` for IPv4 or IPv6 addresses and `generateDNSAlias` for
aliases to fully qualified names defined by local records or other aliases:

```jsonnet
dnsUtils.generateDNSRecord('node.example.com', '192.168.8.205'),
dnsUtils.generateDNSAlias('app.example.com', 'node.example.com'),
```

Both functions keep the declared name and its subdomains local. Missing types
(such as AAAA for an IPv4-only node) are answered without upstream queries.
Public names use the same alias function to resolve through the internal ingress:

```jsonnet
dnsUtils.generateDNSAlias('authentik.aetherrootr.com', 'edge-router.corp.aetherrootr.com'),
```

Add new record files to the imports and combined array in `dns/config.jsonnet`.
Change shared defaults in `dns/utils.libsonnet`.

```sh
# Render locally.
tk eval dns/config.jsonnet

# Apply DNS configuration (replaces /etc/dnsmasq.conf).
ansible-playbook -i inventories/router/host.yaml playbooks/router_dns.yaml \
  --diff
```

To use standalone Jsonnet instead of `tk`, add
`-e '{"dns_jsonnet_command": ["jsonnet"]}'`.
