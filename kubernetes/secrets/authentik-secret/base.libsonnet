local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='authentik-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='4f6da835-00bb-4bf8-a2e5-b3030030248f',
          secretKeyName='authentik-secret-key',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='3a1eb1ef-e024-45c9-877e-b30300304223',
          secretKeyName='postgres-password',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='64847b52-37f4-47f2-8902-b30300306774',
          secretKeyName='redis-password',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='b64d7d45-176f-4548-b6f2-b303002b7506',
          secretKeyName='email-password',
        ),
      ],
    ),
  ],
}
