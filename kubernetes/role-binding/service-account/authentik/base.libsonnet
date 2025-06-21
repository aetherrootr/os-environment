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
          resources: ['services', 'namespaces'],
          verbs: ['get', 'list', 'watch'],
        },
        {
            apiGroups: ['extensions', 'networking.k8s.io'],
            resources: ['ingresses'],
            verbs: ['get', 'list', 'watch'],
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
