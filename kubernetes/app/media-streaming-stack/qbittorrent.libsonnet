local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  deployName:: error ('deployName is required'),
  appName:: 'qbittorrent',
  replicas:: 1,
  port:: 8923,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  urlPrefix:: 'torrent',

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.urlPrefix)],

  local containerImage = 'linuxserver/qbittorrent:4.6.2',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='PUID', value='1000'),
    k8sUtils.generateEnv(name='PGID', value='1000'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
    k8sUtils.generateEnv(name='UMASK_SET', value='022'),
    k8sUtils.generateEnv(name='WEBUI_PORT', value=std.toString($.port)),
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
        cpu: '2000m',
        memory: '2Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/config',
        subPath=std.strReplace($.deployName + '/' + $.appName, '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data/downloads',
        subPath='downloads',
      ),
    ],
  ),

  qbittorrent: std.prune([
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
          {
            name: $.appName + '-data-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='data0',
              ),
            },
          },
        ],
        hostNetwork=true,
        nodeSelector={
          'reserved-app': 'qbittorrent',
        },
        tolerations=[
          {
            key: 'reserved-app',
            operator: 'Equal',
            value: 'qbittorrent',
            effect: 'NoSchedule',
          },
        ],
      ),
      replicas=$.replicas,
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName,
      serviceName=$.appName,
      annotations={},
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
      withAuthProxy=true,
    ),
  ]),
}
