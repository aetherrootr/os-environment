local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'clash-exporter',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
