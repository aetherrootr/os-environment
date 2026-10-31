local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error 'namespace is required',

  apiVersion: 'v1',
  kind: 'List',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='argocd-redis',
      namespace=$.namespace,
      extraLabels={
        'app.kubernetes.io/name': 'argocd-redis',
        'app.kubernetes.io/part-of': 'argocd',
      },
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='d37337a9-d24f-488c-9fa6-b4f4011f62b8',
          secretKeyName='auth',
        ),
      ],
    ),
  ],
}
