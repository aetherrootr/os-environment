local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  deployName:: error ('deployName is required'),
  appName:: 'jellyseerr',
  replicas:: 1,
  port:: 5055,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local containerImage = 'fallenbagel/jellyseerr:2.7.3',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='PUID', value='1000'),
    k8sUtils.generateEnv(name='PGID', value='1000'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
    k8sUtils.generateEnv(name='LOG_LEVEL', value='debug'),
  ]),


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '500m',
        memory: '512Mi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/app/config',
        subPath=std.strReplace($.deployName + '/' + $.appName + '_config', '-', '_'),
      ),
    ],
  ),

  jellyseerr: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
      ],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: $.appName + '-config-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
        ],
      ),
      replicas=$.replicas,
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName,
      serviceName=$.appName,
      annotations={
        'nginx.ingress.kubernetes.io/auth-response-headers': "Authorization,Remote-User"
      },
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
