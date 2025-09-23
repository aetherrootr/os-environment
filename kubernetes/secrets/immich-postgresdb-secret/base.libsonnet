local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='immich-postgresdb-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='deaf3ad2-3f18-4c37-97cd-b36100e28ea1',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
