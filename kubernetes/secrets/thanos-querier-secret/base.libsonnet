local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='thanos-querier-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='5ee60fca-6ca9-448f-8f51-b30400753de4',
          secretKeyName='authentik-proxy-outpost-token')
      ],
    ),
  ],
}
