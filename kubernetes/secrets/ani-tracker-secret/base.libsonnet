local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='ani-tracker-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='6f365a99-cf70-44db-a630-b48500a13e3c',
          secretKeyName='secret-key',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='1f830bf4-acd0-41b6-bda8-b48500a1b4e5',
          secretKeyName='oidc-client-secret',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='178600a5-1199-4738-be01-b48500a22822',
          secretKeyName='tmdb-api-key',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='0c64e52a-a27c-457d-bc12-b48500a2b6a7',
          secretKeyName='tvdb-api-key',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='364952be-6a21-4d8e-bb9f-b48500a319e1',
          secretKeyName='tvdb-pin',
        ),
      ],
    ),
  ],
}
