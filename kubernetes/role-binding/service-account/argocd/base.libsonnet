local k = import 'common/lib/k.libsonnet';
local roleBindingUtils = import 'utils/role-binding-utils.libsonnet';
local serviceAccountUtils = import 'utils/service-account-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  apiVersion: 'v1',
  kind: 'List',
  items: std.prune([
    serviceAccountUtils.generateServiceAccount(
      name='argocd-application-controller',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-applicationset-controller',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-dex-server',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'dex-server',
      'app.kubernetes.io/name': 'argocd-dex-server',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-notifications-controller',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'notifications-controller',
      'app.kubernetes.io/name': 'argocd-notifications-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-redis',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'redis',
      'app.kubernetes.io/name': 'argocd-redis',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-repo-server',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'repo-server',
      'app.kubernetes.io/name': 'argocd-repo-server',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    serviceAccountUtils.generateServiceAccount(
      name='argocd-server',
      namespace=$.namespace,
    ) + k.core.v1.serviceAccount.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    k.rbac.v1.role.new('argocd-application-controller')
    + k.rbac.v1.role.metadata.withNamespace($.namespace)
    + k.rbac.v1.role.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.rbac.v1.role.withRules([
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
          'configmaps',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'applications',
          'applicationsets',
          'appprojects',
        ],
        verbs: [
          'create',
          'get',
          'list',
          'watch',
          'update',
          'patch',
          'delete',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'events',
        ],
        verbs: [
          'create',
          'list',
        ],
      },
      {
        apiGroups: [
          'apps',
        ],
        resources: [
          'deployments',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
    ]),
    k.rbac.v1.role.new('argocd-applicationset-controller')
    + k.rbac.v1.role.metadata.withNamespace($.namespace)
    + k.rbac.v1.role.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.rbac.v1.role.withRules([
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'applications',
          'applicationsets',
          'applicationsets/finalizers',
        ],
        verbs: [
          'create',
          'delete',
          'get',
          'list',
          'patch',
          'update',
          'watch',
        ],
      },
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'appprojects',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'applicationsets/status',
        ],
        verbs: [
          'get',
          'patch',
          'update',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'events',
        ],
        verbs: [
          'create',
          'get',
          'list',
          'patch',
          'watch',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
          'configmaps',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          'coordination.k8s.io',
        ],
        resources: [
          'leases',
        ],
        verbs: [
          'create',
        ],
      },
      {
        apiGroups: [
          'coordination.k8s.io',
        ],
        resourceNames: [
          '58ac56fa.applicationsets.argoproj.io',
        ],
        resources: [
          'leases',
        ],
        verbs: [
          'get',
          'update',
          'create',
        ],
      },
    ]),
    k.rbac.v1.role.new('argocd-dex-server')
    + k.rbac.v1.role.metadata.withNamespace($.namespace)
    + k.rbac.v1.role.metadata.withLabels({
      'app.kubernetes.io/component': 'dex-server',
      'app.kubernetes.io/name': 'argocd-dex-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.rbac.v1.role.withRules([
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
          'configmaps',
        ],
        verbs: [
          'get',
          'list',
          'watch',
        ],
      },
    ]),
    k.rbac.v1.role.new('argocd-notifications-controller')
    + k.rbac.v1.role.metadata.withNamespace($.namespace)
    + k.rbac.v1.role.metadata.withLabels({
      'app.kubernetes.io/component': 'notifications-controller',
      'app.kubernetes.io/name': 'argocd-notifications-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.rbac.v1.role.withRules([
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'applications',
          'appprojects',
        ],
        verbs: [
          'get',
          'list',
          'watch',
          'update',
          'patch',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'configmaps',
          'secrets',
        ],
        verbs: [
          'list',
          'watch',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resourceNames: [
          'argocd-notifications-cm',
        ],
        resources: [
          'configmaps',
        ],
        verbs: [
          'get',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resourceNames: [
          'argocd-notifications-secret',
        ],
        resources: [
          'secrets',
        ],
        verbs: [
          'get',
        ],
      },
    ]),
    k.rbac.v1.role.new('argocd-server')
    + k.rbac.v1.role.metadata.withNamespace($.namespace)
    + k.rbac.v1.role.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.rbac.v1.role.withRules([
      {
        apiGroups: [
          '',
        ],
        resources: [
          'secrets',
          'configmaps',
        ],
        verbs: [
          'create',
          'get',
          'list',
          'watch',
          'update',
          'patch',
          'delete',
        ],
      },
      {
        apiGroups: [
          'argoproj.io',
        ],
        resources: [
          'applications',
          'appprojects',
          'applicationsets',
        ],
        verbs: [
          'create',
          'get',
          'list',
          'watch',
          'update',
          'delete',
          'patch',
        ],
      },
      {
        apiGroups: [
          '',
        ],
        resources: [
          'events',
        ],
        verbs: [
          'create',
          'list',
        ],
      },
    ]),
    roleBindingUtils.generateClusterRole(
      rolename='argocd-application-controller',
      rules=[
        {
          apiGroups: [
            '*',
          ],
          resources: [
            '*',
          ],
          verbs: [
            '*',
          ],
        },
        {
          nonResourceURLs: [
            '*',
          ],
          verbs: [
            '*',
          ],
        },
      ],
    )
    + k.rbac.v1.clusterRole.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    roleBindingUtils.generateClusterRole(
      rolename='argocd-applicationset-controller',
      rules=[
        {
          apiGroups: [
            'argoproj.io',
          ],
          resources: [
            'applications',
            'applicationsets',
            'applicationsets/finalizers',
          ],
          verbs: [
            'create',
            'delete',
            'get',
            'list',
            'patch',
            'update',
            'watch',
          ],
        },
        {
          apiGroups: [
            'argoproj.io',
          ],
          resources: [
            'appprojects',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'argoproj.io',
          ],
          resources: [
            'applicationsets/status',
          ],
          verbs: [
            'get',
            'patch',
            'update',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'events',
          ],
          verbs: [
            'create',
            'get',
            'list',
            'patch',
            'watch',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'secrets',
            'configmaps',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'coordination.k8s.io',
          ],
          resources: [
            'leases',
          ],
          verbs: [
            'create',
          ],
        },
        {
          apiGroups: [
            'coordination.k8s.io',
          ],
          resourceNames: [
            '58ac56fa.applicationsets.argoproj.io',
          ],
          resources: [
            'leases',
          ],
          verbs: [
            'get',
            'update',
            'create',
          ],
        },
      ],
    )
    + k.rbac.v1.clusterRole.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    roleBindingUtils.generateClusterRole(
      rolename='argocd-server',
      rules=[
        {
          apiGroups: [
            '*',
          ],
          resources: [
            '*',
          ],
          verbs: [
            'delete',
            'get',
            'patch',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'events',
          ],
          verbs: [
            'list',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'pods',
            'pods/log',
          ],
          verbs: [
            'get',
          ],
        },
        {
          apiGroups: [
            'argoproj.io',
          ],
          resources: [
            'applications',
            'applicationsets',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'batch',
          ],
          resources: [
            'jobs',
          ],
          verbs: [
            'create',
          ],
        },
        {
          apiGroups: [
            'argoproj.io',
          ],
          resources: [
            'workflows',
          ],
          verbs: [
            'create',
          ],
        },
      ],
    )
    + k.rbac.v1.clusterRole.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    k.rbac.v1.roleBinding.new('argocd-application-controller')
    + k.rbac.v1.roleBinding.metadata.withNamespace($.namespace)
    + k.rbac.v1.roleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + { roleRef: roleBindingUtils.generateRoleRef(
      roleRefName='argocd-application-controller',
      roleRefKind='Role',
    ) }
    + k.rbac.v1.roleBinding.withSubjects([
      {
        kind: 'ServiceAccount',
        name: 'argocd-application-controller',
        namespace: $.namespace,
      },
    ]),
    k.rbac.v1.roleBinding.new('argocd-applicationset-controller')
    + k.rbac.v1.roleBinding.metadata.withNamespace($.namespace)
    + k.rbac.v1.roleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + { roleRef: roleBindingUtils.generateRoleRef(
      roleRefName='argocd-applicationset-controller',
      roleRefKind='Role',
    ) }
    + k.rbac.v1.roleBinding.withSubjects([
      {
        kind: 'ServiceAccount',
        name: 'argocd-applicationset-controller',
        namespace: $.namespace,
      },
    ]),
    k.rbac.v1.roleBinding.new('argocd-dex-server')
    + k.rbac.v1.roleBinding.metadata.withNamespace($.namespace)
    + k.rbac.v1.roleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'dex-server',
      'app.kubernetes.io/name': 'argocd-dex-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + { roleRef: roleBindingUtils.generateRoleRef(
      roleRefName='argocd-dex-server',
      roleRefKind='Role',
    ) }
    + k.rbac.v1.roleBinding.withSubjects([
      {
        kind: 'ServiceAccount',
        name: 'argocd-dex-server',
        namespace: $.namespace,
      },
    ]),
    k.rbac.v1.roleBinding.new('argocd-notifications-controller')
    + k.rbac.v1.roleBinding.metadata.withNamespace($.namespace)
    + k.rbac.v1.roleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'notifications-controller',
      'app.kubernetes.io/name': 'argocd-notifications-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + { roleRef: roleBindingUtils.generateRoleRef(
      roleRefName='argocd-notifications-controller',
      roleRefKind='Role',
    ) }
    + k.rbac.v1.roleBinding.withSubjects([
      {
        kind: 'ServiceAccount',
        name: 'argocd-notifications-controller',
        namespace: $.namespace,
      },
    ]),
    k.rbac.v1.roleBinding.new('argocd-server')
    + k.rbac.v1.roleBinding.metadata.withNamespace($.namespace)
    + k.rbac.v1.roleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + { roleRef: roleBindingUtils.generateRoleRef(
      roleRefName='argocd-server',
      roleRefKind='Role',
    ) }
    + k.rbac.v1.roleBinding.withSubjects([
      {
        kind: 'ServiceAccount',
        name: 'argocd-server',
        namespace: $.namespace,
      },
    ]),
    roleBindingUtils.generateClusterRoleBinding(
      namespace=null,
      roleBindingName='argocd-application-controller',
      serviceAccount=serviceAccountUtils.generateServiceAccount(
        name='argocd-application-controller',
        namespace=$.namespace,
      ),
      roleRef=roleBindingUtils.generateRoleRef(
        roleRefName='argocd-application-controller',
        roleRefKind='ClusterRole',
      ),
    )
    + k.rbac.v1.clusterRoleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    roleBindingUtils.generateClusterRoleBinding(
      namespace=null,
      roleBindingName='argocd-applicationset-controller',
      serviceAccount=serviceAccountUtils.generateServiceAccount(
        name='argocd-applicationset-controller',
        namespace=$.namespace,
      ),
      roleRef=roleBindingUtils.generateRoleRef(
        roleRefName='argocd-applicationset-controller',
        roleRefKind='ClusterRole',
      ),
    )
    + k.rbac.v1.clusterRoleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    }),
    roleBindingUtils.generateClusterRoleBinding(
      namespace=null,
      roleBindingName='argocd-server',
      serviceAccount=serviceAccountUtils.generateServiceAccount(
        name='argocd-server',
        namespace=$.namespace,
      ),
      roleRef=roleBindingUtils.generateRoleRef(
        roleRefName='argocd-server',
        roleRefKind='ClusterRole',
      ),
    )
    + k.rbac.v1.clusterRoleBinding.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    }),
  ]),
}
