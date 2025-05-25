local roleBindingUtils = import 'utils/role-binding-utils.libsonnet';
local serviceAccountUtils = import 'utils/service-account-utils.libsonnet';

{
  appName:: 'prometheus',
  namespace:: error 'namespace is required',

  local serviceAccount = serviceAccountUtils.generateServiceAccount($.appName, $.namespace),
  local clusterRoleRef = roleBindingUtils.generateRoleRef(roleRefName=$.appName, roleRefKind='ClusterRole'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    serviceAccount,
    roleBindingUtils.generateClusterRole(
      rolename=$.appName,
      rules=[
        {
          apiGroups: [''],
          resources: ['pods', 'services', 'endpoints', 'nodes', 'nodes/metrics', 'nodes/proxy'],
          verbs: ['get', 'list', 'watch'],
        },
        {
            nonResourceURLs: ['/metrics', '/metrics/cadvisor', '/healthz', '/version'],
            verbs: ['get'],
        },
      ],
    ),
    roleBindingUtils.generateClusterRoleBinding(
      namespace=$.namespace,
      roleBindingName=$.appName,
      serviceAccount=serviceAccount,
      roleRef=clusterRoleRef,
    ),
  ]),
}
