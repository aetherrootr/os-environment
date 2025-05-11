local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "kubernetes-dashboard",

  deployTarget: base {
    namespace: $.namespace,
  },
}
