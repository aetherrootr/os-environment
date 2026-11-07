# Edge certificates

The shared edge Gateway uses two cert-manager Certificate entries, both in the
`edge-gateway` namespace:

| Entry | Certificate Secret |
| --- | --- |
| [`corp.aetherrootr.com/namespaces/edge-gateway.jsonnet`](corp.aetherrootr.com/namespaces/edge-gateway.jsonnet) | `edge-wildcard-certificate-tls` |
| [`authentik.aetherrootr.com/namespaces/edge-gateway.jsonnet`](authentik.aetherrootr.com/namespaces/edge-gateway.jsonnet) | `edge-gateway-authentik-certificate-tls` |

Bootstrap prepares the DNS credentials and ClusterIssuer, applies these entries,
and waits for both certificates to become Ready before applying the Gateway.
cert-manager renews the certificates. Application-internal TLS and mTLS
certificates remain separate.

The Gateway resource and its listener definitions are maintained under
[`kubernetes/gateway`](../gateway/README.md). A new certificate domain needs a
Certificate entry here, a listener that explicitly references its Secret, and an
HTTPRoute attached to that listener. Issue the certificate before applying its
listener. A new application covered by the wildcard only needs an HTTPRoute.
