local v3 = import '../v3.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

// Deploy only the independent v3 resources, without changing the live v2 ingress.
env {
  namespace:: 'applications-and-services',
  deployTarget: {
    apiVersion: 'v1',
    kind: 'List',
    items: (v3 { namespace: $.namespace }).items,
  },
}
