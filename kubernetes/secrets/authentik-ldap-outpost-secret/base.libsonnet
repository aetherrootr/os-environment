local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error ('namespace is required'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='authentik-ldap-outpost-secret',
      namespace=$.namespace,
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='c0fe15c7-0a97-4325-ae79-b30701288989',
          secretKeyName='authentik-ldap-outpost-token',
        ),
      ],
    ),
  ],
}
