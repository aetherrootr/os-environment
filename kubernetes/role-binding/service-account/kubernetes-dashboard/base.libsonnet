local serviceAccountUtils = import 'utils/service-account-utils.libsonnet';
local roleBindingUtils = import 'utils/role-binding-utils.libsonnet';

{
    appName:: error 'appName is required',
    namespace:: error 'namespace is required',
    
    local serviceAccount = serviceAccountUtils.generateServiceAccount($.appName, $.namespace),
    local clusterRoleRef = roleBindingUtils.generateRoleRef(roleRefName='cluster-admin', roleRefKind='ClusterRole'),

    apiVersion: 'apps/v1',
    kind: 'list',
    items: std.prune([
        serviceAccount,
        roleBindingUtils.generateRoleBinding(
            namespace=null,
            roleBindingName=$.appName,
            serviceAccount=serviceAccount,
            roleRef=clusterRoleRef,
        ),
    ]),
}
