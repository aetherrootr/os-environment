local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='open-webui-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='b8212d9b-10fa-4d1d-8e6f-b4aa01134c65',
          secretKeyName='oidc-client-secret',
        ),
      ],
    ),
  ],
}
