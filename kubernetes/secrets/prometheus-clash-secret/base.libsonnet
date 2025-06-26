local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='prometheus-clash-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='1ddcf78f-a7e3-4837-8246-b30400772362',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
