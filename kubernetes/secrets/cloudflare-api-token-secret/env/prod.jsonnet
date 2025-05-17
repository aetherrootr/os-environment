local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'cert-manager',

  deployTarget: base {
    namespace: $.namespace,
  },
}
