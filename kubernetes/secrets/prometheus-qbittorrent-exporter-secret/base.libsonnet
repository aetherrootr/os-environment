local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='prometheus-qbittorrent-exporter-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='0db81137-760e-4bd7-b280-b2ee0139ee9f',
          secretKeyName='username',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='130afa09-fe5a-4ffb-9121-b2ee013a344e',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
