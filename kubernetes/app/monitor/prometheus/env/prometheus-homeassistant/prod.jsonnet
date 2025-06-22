local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'prometheus-homeassistant',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
    prometheusYml: importstr '../../config/prometheus-homeassistant/prometheus.yml',
    retentionTime: '365d',
    withHomeAssistantToken: true,
    enableAuthProxy: true,
  },
}
