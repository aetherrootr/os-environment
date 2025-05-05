local env = import 'utils/inline-environments-base.libsonnet';
local serviceAccountUtils = import 'utils/service-account-utils.libsonnet';
local roleBindingUtils = import 'utils/role-binding-utils.libsonnet';

env{
    namespace: 'kubernetes-dashboard',
    deployTarget: {
        local appName = 'kubernetes-dashboard',
        local roleName = 'ClusterRole',

        local serviceAccount = serviceAccountUtils.generateServiceAccount(appName, $.namespace),

        local ClusterRoleRef = roleBindingUtils.generateRoleRef(roleRefName=appName, roleRefKind=roleName),

        apiVersion: 'apps/v1',
        kind: 'list',
        items: std.prune([
            serviceAccount,
            roleBindingUtils.generateRoleBinding(
                namespace=$.namespace,
                roleBindingName=appName,
                serviceAccount=serviceAccount,
                roleRef=ClusterRoleRef,
            ),
        ]),
    },
}
