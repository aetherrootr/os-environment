local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  environment:: 'prod',
  namespace:: 'cert-manager',
  cloudflareApiToken:: 'cloudflare-api-token-secret',

  deployTarget: base {
    environment: $.environment,
    cloudflareApiToken: $.cloudflareApiToken,
  },
}
