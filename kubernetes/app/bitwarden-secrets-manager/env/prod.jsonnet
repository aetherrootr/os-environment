local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "bitwarden-secrets-manager",
  appName:: "bw-sm-op",

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
