local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='sonarr-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='cfb1c3cc-d5a4-492e-ba77-b304010f219b',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
