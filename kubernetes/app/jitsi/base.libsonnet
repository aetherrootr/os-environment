local tankaUtils = import 'common/lib/tanka-utils.libsonnet';
local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  local chartPath = './charts/jitsi-meet',
  appName:: error ('appName is required'),
  namespace:: error ('namespace is required'),
  urlPrefix:: 'meet',

  local host = k8sUtils.getServiceHostname(serviceName=$.urlPrefix),


  local jitsi_meet_resources = k8sUtils.importFromHelmChart(
    projectPath=std.thisFile,
    name=$.appName,
    chart=chartPath,
    config={
      values: {
        publicURL: 'https://' + host,
        tz: 'Asia/Shanghai',
        jvb: {
          useHostPort: true,
          useNodeIP: true
        },
        web: {
          ingress: { enabled: false },
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

  routes: k8sUtils.generateHTTPRoutes(
    namespace=$.namespace,
    appName=$.appName,
    serviceName=$.appName + '-jitsi-meet-web',
    port=80,
    httpsListener='https-wildcard',
    hostnameList=[host],
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
