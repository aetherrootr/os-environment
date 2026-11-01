local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'argocd',
  metadataName:: 'argocd-apps-prod',

  deployTarget: base {
    namespace: $.namespace,
  },
}
