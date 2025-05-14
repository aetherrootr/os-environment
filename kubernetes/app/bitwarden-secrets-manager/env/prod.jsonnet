local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "bitwarden-secrets-manager",
  appName:: "smop",

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
