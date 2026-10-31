local secretUtils = import 'utils/secret-utils.libsonnet';

{
  namespace:: error 'namespace is required',

  apiVersion: 'v1',
  kind: 'List',
  items: [
    secretUtils.generateBitwardenSecret(
      secretName='argocd-notifications-secret',
      namespace=$.namespace,
      extraLabels={
        'app.kubernetes.io/component': 'notifications-controller',
        'app.kubernetes.io/name': 'argocd-notifications-controller',
        'app.kubernetes.io/part-of': 'argocd',
      },
      bwSecret=[
        secretUtils.generateBwSecret(
          bwSecretId='a4ea678f-db73-4e9e-9342-b4f4012ad350',
          secretKeyName='smtp-password',
        ),
      ],
    ),
  ],
}
