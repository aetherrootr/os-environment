local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='radarr-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='99213be8-e2bc-4f02-8ece-b304011ba633',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
