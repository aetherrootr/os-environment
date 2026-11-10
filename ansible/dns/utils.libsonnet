// DNS names and targets are used exactly as supplied by the caller.
{
  // Declared names and their subdomains are resolved locally, including missing types.
  // dnsmasq --test validates the generated address syntax before deployment.
  generateDNSRecord(name, address)::
    'local=/' + name + '/\nhost-record=' + name + ',' + address,

  // Targets must be fully qualified names defined by local records or aliases.
  generateDNSAlias(name, target)::
    'local=/' + name + '/\ncname=' + name + ',' + target,

  defaults:: [
    '# Managed by Ansible. Do not edit directly.',
    '# Repository: https://github.com/aetherrootr/os-environment',
    '# Edit: ansible/dns/*.libsonnet and ansible/dns/config.jsonnet.',
    // Static DNS comes from this configuration, not the router's /etc/hosts.
    'no-hosts',
    // Resolve corp.aetherrootr.com and all its subdomains locally; no '*' is needed.
    // Declared names keep their configured addresses or aliases. Undeclared names
    // return NXDOMAIN immediately; this does not map every name to the same IP.
    // OpenClash forwards this zone to dnsmasq, so forwarding unknown names back
    // to OpenClash would create a loop that ends only when the query times out.
    'local=/corp.aetherrootr.com/',
    'local-ttl=60',
    'host-record=localhost,127.0.0.1,::1',
  ],

  generateDnsmasqConfig(records)::
    local defaults = self.defaults;
    { dnsmasq_conf: std.join('\n', defaults + records) + '\n' },
}
