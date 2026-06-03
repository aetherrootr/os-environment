local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'cloudflare-tunnel',
  appName:: 'cloudflared',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
