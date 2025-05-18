local tankaUtils = import 'common/lib/tanka-utils.libsonnet';
local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  local chartPath = './charts/jitsi-meet',
  appName:: error ('appName is required'),
  namespace:: error ('namespace is required'),
  urlPrefix:: 'meet',
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local host = k8sUtils.getServiceHostname(serviceName=$.urlPrefix),


  local jitsi_meet_resources = k8sUtils.importFromHelmChart(
    projectPath=std.thisFile,
    name=$.appName,
    chart=chartPath,
    config={
      values: {
        tz: 'Asia/Shanghai',
        jvb: {
          service: {
            type: 'NodePort',
            nodePort: 30000,
          },
          publicIPs: [
            '192.168.8.185',
            '192.168.8.152',
          ],
        },
        web: {
          ingress: {
            enabled: true,
            ingressClassName: 'nginx',
            annotations: {
              'kubernetes.io/ingress.class': 'nginx',
              'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
              'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
              'nginx.ingress.kubernetes.io/use-port-in-redirects': 'true',
            },
            hosts: [
              {
                host: host,
                paths: ['/'],
              },
            ],
            tls: [
              {
                secretName: $.certificateName,
                hosts: [
                  host,
                ],
              },
            ],
          },
        },
        prosody: {
          persistence: {
            enabled: false,
          },
        },
      },
      namespace: $.namespace,
    },
  ),

  jitsi_meet: tankaUtils.k8s.patchKubernetesObjects(
    jitsi_meet_resources,
    {
      metadata+: {
        namespace: $.namespace,
      },
    }
  ),
}
