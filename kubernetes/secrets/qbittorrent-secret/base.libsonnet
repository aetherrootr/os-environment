local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='qbittorrent-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='e52f8a69-9cb0-4e68-9efa-b3040124a306',
          secretKeyName='authentik-proxy-outpost-token',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='4416be45-7b7e-42a4-9019-b31d01251f59',
          secretKeyName='auth',
        ),
      ],
    ),
  ],
}
