local dnsUtils = import 'utils.libsonnet';
local nodes = import 'nodes.libsonnet';
local applications = import 'applications.libsonnet';
local storages = import 'storages.libsonnet';

dnsUtils.generateDnsmasqConfig(nodes + applications + storages)
