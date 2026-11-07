# Edge certificates and listeners

The shared `edge-gateway/edge-gateway` Gateway and its listeners are defined in
[`edge-gateway/base.libsonnet`](edge-gateway/base.libsonnet), alongside the
Certificate projects. Ansible installs the Envoy Gateway controller, GatewayClass,
EnvoyProxy and ClientTrafficPolicy. It does not apply the Gateway object.

Each HTTPS listener explicitly binds a hostname to one certificate Secret:

| Listener | Hostname | Secret in `edge-gateway` |
| --- | --- | --- |
| `https-wildcard` | `*.corp.aetherrootr.com` | `edge-wildcard-certificate-tls` |
| `https-authentik` | `authentik.aetherrootr.com` | `edge-gateway-authentik-certificate-tls` |

HTTPRoutes select a listener through `parentRefs.sectionName`. Every call to
`generateHTTPRoutes` must explicitly pass `httpsListener='https-wildcard'` or
`httpsListener='https-authentik'`; there is no default. HTTP-only calls pass
`httpsListener=null` and `tls=false`. SNI selects the matching listener during
the TLS handshake; each listener uses its single configured certificate.

Bootstrap issues both certificates, waits for them to become Ready, applies the
Gateway, and waits for Programmed before installing Argo CD. The Gateway and
Certificates are applied through Tanka; they are not registered as Argo CD
Applications. cert-manager handles renewal.

To update listeners after editing their Jsonnet definition, run from the
repository root:

```bash
(cd kubernetes/certificates/edge-gateway && jb install)
tk apply kubernetes/certificates/edge-gateway/env/prod.jsonnet
```

A new hostname covered by the wildcard only needs an HTTPRoute explicitly
attached to `https-wildcard`. Other certificate domains need a Certificate entry
in `edge-gateway`, a listener with an explicit hostname and certificate reference,
and an explicitly attached route. Issue the certificate before applying that
listener. Application-internal TLS and mTLS certificates remain separate.
