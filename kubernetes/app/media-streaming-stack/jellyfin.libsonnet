local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  deployName:: error ('deployName is required'),
  appName:: 'jellyfin',
  replicas:: 1,
  port:: 8096,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local containerImage = 'nyanmisaka/jellyfin:250627-amd64',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='PUID', value='0'),
    k8sUtils.generateEnv(name='PGID', value='0'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
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
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/config',
        subPath=std.strReplace($.deployName + '/' + $.appName + '_config', '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
      ),
      k8sUtils.generateVolumeMount(
        name='dev-dri',
        mountPath='/dev/dri',
      ),
    ],
    privileged=true,
  ),

  jellyfin: std.prune([
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
          k8sUtils.generateHostPathVolume(
            name='dev-dri',
            path='/dev/dri',
            type='Directory',
          ),
        ],
        nodeSelector={
          gpu: 'intel',
        },
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
    ),
  ]),
}
