local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='sgcc-electricity-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='35095cda-1035-467e-9356-b2e2010613c7',
          secretKeyName='phone-number',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='21a0e2c4-41db-4f82-a997-b2e20106584a',
          secretKeyName='password',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='777c0675-7376-45dc-bb40-b2e20106f721',
          secretKeyName='hass-token',
        ),
      ],
    ),
  ],
}
