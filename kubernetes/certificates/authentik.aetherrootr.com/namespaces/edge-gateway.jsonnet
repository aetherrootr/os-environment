local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'edge-gateway',

  deployTarget: base {
    namespace: $.namespace,
    name: 'edge-authentik-certificate',
  },
}
