local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'prometheus',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
