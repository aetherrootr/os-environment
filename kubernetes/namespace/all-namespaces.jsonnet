local allNamespaces = import 'all-namespaces.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace: 'default',
  deployTarget: allNamespaces,
}
