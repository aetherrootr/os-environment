local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'argocd',

  spec+: {
    applyStrategy: 'server',
  },

  deployTarget: base {
    namespace: $.namespace,
    notificationEmailUsername: 'argocd@aetherrootr.com',
  },
}
