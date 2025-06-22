local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'prometheus-common',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
    prometheusYml: importstr '../../config/prometheus-common/prometheus.yml',
    retentionTime: '90d',
    withHomeAssistantToken: false,
    enableAuthProxy: true,
  },
}
