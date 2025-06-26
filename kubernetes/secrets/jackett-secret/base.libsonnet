local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='jackett-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='b34a9674-5d85-457a-8d82-b3040116c057',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
