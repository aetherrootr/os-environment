local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'gitea',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
