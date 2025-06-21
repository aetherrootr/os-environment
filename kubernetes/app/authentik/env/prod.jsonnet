local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  appName:: 'authentik',
  namespace:: 'infrastructure',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
