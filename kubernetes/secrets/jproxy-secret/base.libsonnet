local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='jproxy-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='dc28c4fc-f409-4cd9-8b26-b30400fbfb40',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
