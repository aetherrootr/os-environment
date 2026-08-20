local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='open-webui-postgres-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='979539c3-78a8-440d-a4d9-b4ac00f9adc0',
          secretKeyName='password',
        ),
      ],
    ),
  ],
}
