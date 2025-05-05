local k = import 'common/lib/k.libsonnet';

{
    tk: (k.rbac.v1),

    generateRoleBinding(namespace, roleBindingName, serviceAccount, roleRef):
        $.tk.roleBinding.new(roleBindingName)
        + $.tk.roleBinding.metadata.withNamespace(namespace)
        + $.tk.roleBinding.withSubjects(
            $.tk.subject.fromServiceAccount(serviceAccount))
        + $.tk.roleBinding.roleRef.withName(roleRef.name)
        + $.tk.roleBinding.roleRef.withKind(roleRef.kind)
        + $.tk.roleBinding.roleRef.withApiGroup(roleRef.apiGroup),

    generateRoleRef(roleRefName, roleRefKind, roleApiGroup='rbac.authorization.k8s.io'):
        $.tk.roleRef.withName(roleRefName)
        + $.tk.roleRef.withKind(roleRefKind)
        + $.tk.roleRef.withApiGroup(roleApiGroup),

}
