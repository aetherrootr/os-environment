local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'kube-monitor',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
