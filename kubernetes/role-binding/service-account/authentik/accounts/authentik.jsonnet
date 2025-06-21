local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'authentik',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
