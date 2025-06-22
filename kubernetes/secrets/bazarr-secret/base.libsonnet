local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='bazarr-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='369bb5e7-546e-4cdf-a31b-b30401186608',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
