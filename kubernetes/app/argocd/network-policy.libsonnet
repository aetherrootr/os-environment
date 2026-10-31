local k = import 'common/lib/k.libsonnet';

{
  namespace:: error 'namespace is required',
  networkPolicy: [
    k.networking.v1.networkPolicy.new('argocd-application-controller-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'application-controller',
      'app.kubernetes.io/name': 'argocd-application-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-application-controller',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            namespaceSelector: {},
          },
        ],
        ports: [
          {
            port: 8082,
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-applicationset-controller-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'applicationset-controller',
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-applicationset-controller',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            namespaceSelector: {},
          },
        ],
        ports: [
          {
            port: 7000,
            protocol: 'TCP',
          },
          {
            port: 8080,
            protocol: 'TCP',
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-dex-server-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'dex-server',
      'app.kubernetes.io/name': 'argocd-dex-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-dex-server',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-server',
              },
            },
          },
        ],
        ports: [
          {
            port: 5556,
            protocol: 'TCP',
          },
          {
            port: 5557,
            protocol: 'TCP',
          },
        ],
      },
      {
        from: [
          {
            namespaceSelector: {},
          },
        ],
        ports: [
          {
            port: 5558,
            protocol: 'TCP',
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-notifications-controller-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'notifications-controller',
      'app.kubernetes.io/name': 'argocd-notifications-controller',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-notifications-controller',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            namespaceSelector: {},
          },
        ],
        ports: [
          {
            port: 9001,
            protocol: 'TCP',
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-redis-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'redis',
      'app.kubernetes.io/name': 'argocd-redis',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-redis',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-server',
              },
            },
          },
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-repo-server',
              },
            },
          },
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-application-controller',
              },
            },
          },
        ],
        ports: [
          {
            port: 6379,
            protocol: 'TCP',
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-repo-server-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'repo-server',
      'app.kubernetes.io/name': 'argocd-repo-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-repo-server',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {
        from: [
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-server',
              },
            },
          },
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-application-controller',
              },
            },
          },
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-notifications-controller',
              },
            },
          },
          {
            podSelector: {
              matchLabels: {
                'app.kubernetes.io/name': 'argocd-applicationset-controller',
              },
            },
          },
        ],
        ports: [
          {
            port: 8081,
            protocol: 'TCP',
          },
        ],
      },
      {
        from: [
          {
            namespaceSelector: {},
          },
        ],
        ports: [
          {
            port: 8084,
          },
        ],
      },
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
    k.networking.v1.networkPolicy.new('argocd-server-network-policy')
    + k.networking.v1.networkPolicy.metadata.withNamespace($.namespace)
    + k.networking.v1.networkPolicy.metadata.withLabels({
      'app.kubernetes.io/component': 'server',
      'app.kubernetes.io/name': 'argocd-server',
      'app.kubernetes.io/part-of': 'argocd',
    })
    + k.networking.v1.networkPolicy.spec.podSelector.withMatchLabels({
      'app.kubernetes.io/name': 'argocd-server',
    })
    + k.networking.v1.networkPolicy.spec.withIngress([
      {},
    ])
    + k.networking.v1.networkPolicy.spec.withPolicyTypes([
      'Ingress',
    ]),
  ],
}
