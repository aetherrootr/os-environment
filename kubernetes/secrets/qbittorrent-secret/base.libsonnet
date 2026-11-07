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
          bwSecretId='48172d98-a626-4e97-adbf-b4fb015b546f',
          secretKeyName='.htpasswd',
        ),
      ],
    ),
  ],
}
