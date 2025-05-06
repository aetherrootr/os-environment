// ref: https://tanka.dev/inline-environments
{
  deployTarget:: error 'data is not set',
  namespace:: error 'namespace is not set',
  apiServer:: "https://k8s-master.corp.aetherrootr.com:6443",
  metadataName:: 'default',

  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: $.metadataName,
    namespace: $.namespace,
  },
  spec: {
    apiServer: $.apiServer,
  },
  data: $.deployTarget,
}
