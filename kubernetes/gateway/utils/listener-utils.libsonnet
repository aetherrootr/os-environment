{
  generateHTTPListener(name, port): {
    name: name,
    protocol: 'HTTP',
    port: port,
    allowedRoutes: {
      namespaces: { from: 'All' },
      kinds: [{ group: 'gateway.networking.k8s.io', kind: 'HTTPRoute' }],
    },
  },

  generateHTTPSListener(name, hostname, certificateSecretName, port=443):
    $.generateHTTPListener(name, port) + {
      protocol: 'HTTPS',
      hostname: hostname,
      tls: {
        mode: 'Terminate',
        certificateRefs: [{ group: '', kind: 'Secret', name: certificateSecretName }],
      },
    },
}
