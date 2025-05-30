local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'prometheus-clash',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
    prometheusYml: importstr '../../config/prometheus-clash/prometheus.yml',
    retentionTime: '45d',
    disableThanosSidecar: true,
    rulesConfig: {
      'clash.yml': importstr '../../rules/clash.yml',
    },
  },
}
