local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'argocd',

  deployTarget: base {
    namespace: $.namespace,
  },
}
