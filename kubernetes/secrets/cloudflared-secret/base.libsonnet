local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='cloudflared-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='d77b0eaa-dff8-41b2-8f92-b45e0110f79f',
          secretKeyName='tunnel_token',
        ),
      ],
    ),
  ],
}
