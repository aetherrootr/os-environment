{
  namespace:: error ('namespace is required'),
  openWebuiAppName:: error ('openWebuiAppName is required'),
  openTerminalAppName:: error ('openTerminalAppName is required'),
  openTerminalPort:: 8000,

  // Keep these aligned with kubeadm serviceSubnet, podSubnet, and Calico IPPools.
  podCidrsV4:: ['10.244.0.0/16'],
  podCidrsV6:: ['2001:db8:42:0::/56'],
  serviceCidrsV4:: ['10.96.0.0/12'],
  serviceCidrsV6:: ['2001:db8:42:1::/112'],

  networkPolicy: [{
    apiVersion: 'crd.projectcalico.org/v1',
    kind: 'NetworkPolicy',
    metadata: {
      name: 'restrict-' + $.openTerminalAppName,
      namespace: $.namespace,
    },
    spec: {
      // Calico evaluates rules in order, so specific allows must precede denies.
      order: 100,
      selector: 'app == "' + $.openTerminalAppName + '"',
      types: ['Ingress', 'Egress'],
      ingress: [
        // Open Terminal is internal-only and accepts requests from Open WebUI.
        {
          action: 'Allow',
          protocol: 'TCP',
          source: {
            selector: 'app == "' + $.openWebuiAppName + '"',
            namespaceSelector: 'projectcalico.org/name == "' + $.namespace + '"',
          },
          destination: { ports: [$.openTerminalPort] },
        },
        { action: 'Deny' },
      ],
      egress: [
        // DNS is required before cluster service traffic is denied below.
        {
          action: 'Allow',
          protocol: 'UDP',
          destination: { services: { name: 'kube-dns', namespace: 'kube-system' } },
        },
        {
          action: 'Allow',
          protocol: 'TCP',
          destination: { services: { name: 'kube-dns', namespace: 'kube-system' } },
        },
        {
          action: 'Deny',
          ipVersion: 4,
          destination: {
            // Block cluster, private, loopback, link-local, and reserved networks.
            nets: $.podCidrsV4 + $.serviceCidrsV4 + [
              '10.0.0.0/8',
              '100.64.0.0/10',
              '127.0.0.0/8',
              '169.254.0.0/16',
              '172.16.0.0/12',
              '192.168.0.0/16',
              '224.0.0.0/4',
              '240.0.0.0/4',
            ],
          },
        },
        {
          action: 'Deny',
          ipVersion: 6,
          destination: {
            // Calico requires IPv4 and IPv6 CIDRs to be in separate rules.
            nets: $.podCidrsV6 + $.serviceCidrsV6 + [
              '::1/128',
              'fc00::/7',
              'fe80::/10',
              'ff00::/8',
            ],
          },
        },
        // Permit public Internet destinations after internal ranges are denied.
        { action: 'Allow', ipVersion: 4, destination: { nets: ['0.0.0.0/0'] } },
        { action: 'Allow', ipVersion: 6, destination: { nets: ['::/0'] } },
        // Deny anything not explicitly matched above.
        { action: 'Deny' },
      ],
    },
  }],
}
