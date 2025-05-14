local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "cert-manager",

  deployTarget: base {
    namespace: $.namespace,
  },
}
