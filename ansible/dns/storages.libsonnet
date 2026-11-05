local dnsUtils = import 'utils.libsonnet';

[
  dnsUtils.generateDNSRecord('service_data_nfs.corp.aetherrootr.com', '192.168.8.2'),
  dnsUtils.generateDNSRecord('data0_nfs.corp.aetherrootr.com', '192.168.8.2'),
  dnsUtils.generateDNSRecord('data1_nfs.corp.aetherrootr.com', '192.168.8.2'),
]
