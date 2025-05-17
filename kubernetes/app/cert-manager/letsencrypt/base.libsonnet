{
  namespace:: 'cert-manager',
  name:: 'letsencrypt-dns-cloudflare',
  email:: 'aetherrootr@outlook.com',
  environment:: error 'Please set the environment variable "environment" to either "dev" or "prod"',
  cloudflareApiToken:: error 'Please set the environment variable "cloudflareApiToken" to your Cloudflare API token',

  local server = if $.environment == 'dev' then
    'https://acme-staging-v02.api.letsencrypt.org/directory'
  else
    'https://acme-v02.api.letsencrypt.org/directory',

  apiVersion: 'cert-manager.io/v1',
  kind: 'ClusterIssuer',
  metadata: {
    name: $.name,
  },
  spec: {
    acme: {
      email: $.email,
      server: server,
      privateKeySecretRef: {
        name: $.name + '-account-key',
      },
      solvers: [
        {
          dns01: {
            cloudflare: {
              email: $.email,
              apiTokenSecretRef: {
                name: $.cloudflareApiToken,
                key: 'api-token',
              },
            },
          },
        },
      ],
    },
  },
}
