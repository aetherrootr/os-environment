local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='kubernetes-dashboard-csrf',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='7c79fa3a-15ca-47c8-8156-b2dd011ba9ed',
          secretKeyName='csrf',
        ),
      ],
    ),
  ],
}
