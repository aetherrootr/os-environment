local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'cloudflare-tunnel',

  deployTarget: base {
    namespace: $.namespace,
  },
}
