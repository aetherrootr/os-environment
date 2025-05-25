local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='prometheus-clash-exporter-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='78506ddc-de78-4299-a3a7-b2e8002c1dab',
          secretKeyName='token',
        ),
      ],
    ),
  ],
}
