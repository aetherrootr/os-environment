local roleBindingUtils = import 'utils/role-binding-utils.libsonnet';
local serviceAccountUtils = import 'utils/service-account-utils.libsonnet';

{
  appName:: error 'appName is required',
  namespace:: error 'namespace is required',

  local serviceAccount = serviceAccountUtils.generateServiceAccount($.appName, $.namespace),
  local clusterRoleRef = roleBindingUtils.generateRoleRef(roleRefName='cluster-admin', roleRefKind='ClusterRole'),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    serviceAccount,
    roleBindingUtils.generateClusterRoleBinding(
      namespace=null,
      roleBindingName=$.appName,
      serviceAccount=serviceAccount,
      roleRef=clusterRoleRef,
    ),
  ]),
}
