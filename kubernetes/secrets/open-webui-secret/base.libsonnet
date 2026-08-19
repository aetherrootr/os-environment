local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  openTerminalApiKeyBwSecretId:: error ('openTerminalApiKeyBwSecretId is required'),

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
        secretUtils.generateBwSecret(
          bwSecretId='0b9d3dd9-8f5e-4a1f-9344-b4ab011c47cd',
          secretKeyName='open-terminal-api-key',
        ),
      ],
    ),
  ],
}
