local base = import "../base.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  namespace:: "applications-and-services",
  appName:: "filebrowser",

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
