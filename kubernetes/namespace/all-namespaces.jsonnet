local allNamespaces = import "all-namespaces.libsonnet";
local env = import "utils/inline-environments-base.libsonnet";

env {
  deployTarget: allNamespaces,
}
