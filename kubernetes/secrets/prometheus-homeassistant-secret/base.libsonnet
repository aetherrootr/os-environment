local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='prometheus-homeassistant-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='1fff4c8c-b881-4f34-85b6-b2e701104aca',
          secretKeyName='token',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='6d48d78f-df3f-4e56-b8e0-b30400efac2e',
          secretKeyName='authentik-proxy-outpost-token',
        ),
      ],
    ),
  ],
}
