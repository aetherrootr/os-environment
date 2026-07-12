local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  redisDatabaseHost:: error ('redisDatabaseHost is required'),
  redisDatabasePort:: error ('redisDatabasePort is required'),
  replicas:: 1,

  local containerImage = 'redis:7-alpine',

  local containers = k8sUtils.generateContainers(
    containerName=$.redisDatabaseHost,
    image=containerImage,
    command=['redis-server', '--appendonly', 'yes'],
    ports=[
      k8sUtils.generateContainerPort(name='tcp', containerPort=$.redisDatabasePort),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1Gi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
        subPath=std.strReplace($.appName + '/redis', '-', '_'),
      ),
    ],
  ),

  redis: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.redisDatabaseHost,
      ports=[
        k8sUtils.generateServicePort(name='tcp', port=$.redisDatabasePort, targetPort=$.redisDatabasePort),
      ],
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.redisDatabaseHost,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: $.appName + '-data-pvc',
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
  ]),
}
