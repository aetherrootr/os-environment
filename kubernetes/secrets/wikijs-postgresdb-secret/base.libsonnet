local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='wikijs-postgresdb-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='50db3586-1a53-45ae-9e8e-b2dd01343690',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
