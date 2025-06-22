local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='cloud-clipboard-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='d214822f-5947-4870-91f8-b304014a5ce2',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
