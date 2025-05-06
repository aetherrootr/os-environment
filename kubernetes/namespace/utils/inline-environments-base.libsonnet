// ref: https://tanka.dev/inline-environments
{
  deployTarget:: error 'data is not set',
  apiServer:: "https://k8s-master.corp.aetherrootr.com:6443",
  metadataName:: 'namespace-list',

  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: $.metadataName,
  },
  spec: {
    apiServer: $.apiServer,
  },
  data: $.deployTarget,
}
