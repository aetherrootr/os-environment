{
  generateCertificate(name, namespace, dnsNames, issuer='letsencrypt-dns-cloudflare'): {
    apiVersion: 'cert-manager.io/v1',
    kind: 'Certificate',
    metadata: {
      name: name,
      namespace: namespace,
    },
    spec: {
      secretName: name + '-tls',
      issuerRef: {
        name: issuer,
        kind: 'ClusterIssuer',
      },
      commonName: dnsNames[0],
      dnsNames: dnsNames,
      duration: '2160h',
      renewBefore: '360h',
    },
  },
}
