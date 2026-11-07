local listenerUtils = import 'utils/listener-utils.libsonnet';

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
      listenerUtils.generateHTTPListener(name='http', port=80),
      listenerUtils.generateHTTPSListener(
        name='https-wildcard',
        hostname='*.corp.aetherrootr.com',
        certificateSecretName='edge-wildcard-certificate-tls',
      ),
      listenerUtils.generateHTTPSListener(
        name='https-authentik',
        hostname='authentik.aetherrootr.com',
        certificateSecretName='edge-gateway-authentik-certificate-tls',
      ),
    ],
  },
}
