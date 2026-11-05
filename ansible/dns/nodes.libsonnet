// Server nodes: physical hosts or VMs. DNS does not configure DHCP.
local dnsUtils = import 'utils.libsonnet';

[
  dnsUtils.generateDNSRecord('edge-router.corp.aetherrootr.com', '192.168.8.205'),
  dnsUtils.generateDNSRecord('k8s-master.corp.aetherrootr.com', '192.168.8.152'),
  dnsUtils.generateDNSRecord('k8s-node-1.corp.aetherrootr.com', '192.168.8.185'),
  dnsUtils.generateDNSRecord('k8s-node-2.corp.aetherrootr.com', '192.168.8.169'),
  dnsUtils.generateDNSRecord('tailscale-backup-exit-node.corp.aetherrootr.com', '192.168.8.213'),
  dnsUtils.generateDNSRecord('tailscale-exit-node.corp.aetherrootr.com', '192.168.8.220'),
  dnsUtils.generateDNSRecord('vm-server-1.corp.aetherrootr.com', '192.168.8.136'),
]
