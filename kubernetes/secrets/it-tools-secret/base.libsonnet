local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='it-tools-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='7f26c5ef-dbc7-43fd-b810-b304013be836',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
