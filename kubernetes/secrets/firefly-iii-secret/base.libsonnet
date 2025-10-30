local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='firefly-iii-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='5a20c5b9-8871-4f17-8f99-b37f00edcfec',
          secretKeyName='app-key',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='bb9f2e74-1e1e-4598-8357-b37f00ee15ed',
          secretKeyName='db-password',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='f3af73ec-ee73-4446-90f6-b37f00ee4963',
          secretKeyName='static-cron-token',
        ),
      ],
    ),
  ],
}
