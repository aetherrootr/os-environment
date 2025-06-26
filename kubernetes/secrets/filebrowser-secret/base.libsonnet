local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='filebrowser-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='79b2e0c2-aaa1-484f-9eb5-b307010db6b4',
          secretKeyName='config.yaml',
        ),
      ],
    ),
  ],
}
