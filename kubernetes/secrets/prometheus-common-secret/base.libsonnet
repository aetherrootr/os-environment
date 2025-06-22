local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='prometheus-common-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='ae28a12a-1d1b-4d3d-b2d2-b30400ecc5f3',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
