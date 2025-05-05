local env = import 'utils/inline-environments-base.libsonnet';
local allNamespaces = import 'all-namespaces.libsonnet';

env{
  deployTarget: allNamespaces,
}
