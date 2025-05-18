local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  deployName:: error ('deployName is required'),
  appName:: 'jproxy',
  replicas:: 1,
  port:: 8117,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local containerImage = 'luckypuppy514/jproxy:latest',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='PUID', value='1000'),
    k8sUtils.generateEnv(name='PGID', value='1000'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
    k8sUtils.generateEnv(name='JAVA_OPTS', value='-Xms512m -Xmx512m'),
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
        mountPath='/app/database',
        subPath=std.strReplace($.deployName + '/' + $.appName, '-', '_'),
      ),
    ],
  ),

  jproxy: std.prune([
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
      annotations={},
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
