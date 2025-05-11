// ref: https://tanka.dev/inline-environments
{
  deployTarget:: error "data is not set",
  apiServer:: "https://k8s-master.corp.aetherrootr.com:6443",
  namespace:: error "namespace is not set",
  metadataName:: "env/default",

  apiVersion: "tanka.dev/v1alpha1",
  kind: "Environment",
  metadata: {
    name: $.metadataName,
  },
  spec: {
    apiServer: $.apiServer,
    namespace: $.namespace,
  },
  data: $.deployTarget,
}
