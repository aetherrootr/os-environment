local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='ani-tracker-postgres-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='46690ca1-17ee-4171-89cb-b48500a36c65',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
