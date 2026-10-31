local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error 'namespace is required',

  apiVersion: 'v1',
  kind: 'List',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='argocd-secret',
      namespace=$.namespace,
      extraLabels={
        'app.kubernetes.io/name': 'argocd-secret',
        'app.kubernetes.io/part-of': 'argocd',
      },
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='06e54cc3-1b03-4eef-98c5-b4f4011c5471',
          secretKeyName='admin.password',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='50b66d42-889e-43ee-9427-b4f4011c7c93',
          secretKeyName='server.secretkey',
        ),
        secretUtils.generateBwSecret(
          bwSecretId='19caacb0-9ebc-4b8d-a167-b4f4013fe99f',
          secretKeyName='dex.authentik.clientSecret',
        ),
      ],
    ),
  ],
}
