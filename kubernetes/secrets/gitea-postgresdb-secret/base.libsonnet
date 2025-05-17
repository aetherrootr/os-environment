local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='gitea-postgresdb-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='e27242ba-ebbc-4d5f-92ec-b2e001172c79',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
