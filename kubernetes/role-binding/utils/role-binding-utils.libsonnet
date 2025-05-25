local k = import 'common/lib/k.libsonnet';

{
  tk: (k.rbac.v1),

  generateClusterRoleBinding(namespace, roleBindingName, serviceAccount, roleRef): {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      name: roleBindingName,
    } + (if namespace != null then { namespace: namespace } else {}),
    roleRef: {
      apiGroup: roleRef.apiGroup,
      kind: roleRef.kind,
      name: roleRef.name,
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: serviceAccount.metadata.name,
        namespace: serviceAccount.metadata.namespace,
      },
    ],
  },

  generateRoleRef(roleRefName, roleRefKind, roleApiGroup='rbac.authorization.k8s.io'):
    $.tk.roleRef.withName(roleRefName)
    + $.tk.roleRef.withKind(roleRefKind)
    + $.tk.roleRef.withApiGroup(roleApiGroup),
  
  generateClusterRole(rolename, rules=[]):
    $.tk.clusterRole.new(rolename)
    + $.tk.clusterRole.metadata.withName(rolename)
    + $.tk.clusterRole.withRules(rules)


}
