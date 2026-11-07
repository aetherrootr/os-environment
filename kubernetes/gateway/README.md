# Shared edge Gateway

The shared Envoy Gateway `edge-gateway/edge-gateway` provides HTTP and HTTPS
access to cluster applications.

| Listener | Protocol | Port | Hostname |
| --- | --- | --- | --- |
| `http` | HTTP | 80 | All |
| `https-wildcard` | HTTPS | 443 | `*.corp.aetherrootr.com` |
| `https-authentik` | HTTPS | 443 | `authentik.aetherrootr.com` |

[Gateway configuration](edge-gateway/base.libsonnet) ·
[Certificates](../certificates/README.md)
