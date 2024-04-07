local tanka = import "github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet";
local helm = tanka.helm.new(std.thisFile);

{
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: 'environment/default'
  },
  spec: {
    apiServer: "https://192.168.8.145:6443",
    namespace: "kubernetes-dashboard",
  },
  data: helm.template("kubernetes-dashboard", "../../charts/kubernetes-dashboard", {
      namespace: "kubernetes-dashboard",
  }),
}
