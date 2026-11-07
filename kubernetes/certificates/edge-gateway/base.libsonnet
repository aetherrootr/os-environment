{
  namespace:: error 'namespace is required',

  apiVersion: 'gateway.networking.k8s.io/v1',
  kind: 'Gateway',
  metadata: {
    name: 'edge-gateway',
    namespace: $.namespace,
  },
  spec: {
    gatewayClassName: 'envoy',
    listeners: [
      {
        name: 'http',
        protocol: 'HTTP',
        port: 80,
        allowedRoutes: {
          namespaces: { from: 'All' },
          kinds: [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute' }],
        },
      },
      {
        name: 'https-wildcard',
        protocol: 'HTTPS',
        port: 443,
        hostname: '*.corp.aetherrootr.com',
        allowedRoutes: {
          namespaces: { from: 'All' },
          kinds: [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute' }],
        },
        tls: {
          mode: 'Terminate',
          certificateRefs: [{ group: '', kind: 'Secret', name: 'edge-wildcard-certificate-tls' }],
        },
      },
      {
        name: 'https-authentik',
        protocol: 'HTTPS',
        port: 443,
        hostname: 'authentik.aetherrootr.com',
        allowedRoutes: {
          namespaces: { from: 'All' },
          kinds: [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute' }],
        },
        tls: {
          mode: 'Terminate',
          certificateRefs: [{ group: '', kind: 'Secret', name: 'edge-gateway-authentik-certificate-tls' }],
        },
      },
    ],
  },
}
