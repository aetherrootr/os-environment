local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "kubernetes-dashboard",
  appName:: "dashboard-admin",

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  }.items + [{
    apiVersion: "v1",
    kind: "Secret",
    metadata: {
      name: "dashboard-admin-token",
      namespace: $.namespace,
      annotations: {
        "kubernetes.io/service-account.name": $.appName,
      },
    },
    type: "kubernetes.io/service-account-token",
  }],
}
