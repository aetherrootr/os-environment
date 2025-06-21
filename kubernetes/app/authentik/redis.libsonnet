local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  redisDatabaseHost:: error ('databaseHost is required'),
  redisDatabasePort:: error ('databasePort is required'),
  redisDatabasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  replicas:: 1,

  local containerImage = 'bitnami/redis:latest',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='REDIS_PORT_NUMBER', value=std.toString($.redisDatabasePort)),
    k8sUtils.generateSecretEnv(name='REDIS_PASSWORD', secretName=$.redisDatabasePasswordSecretName, key='redis-password'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.redisDatabaseHost,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.redisDatabasePort),
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
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
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
        k8sUtils.generateServicePort(name='http', port=$.redisDatabasePort, targetPort=$.redisDatabasePort),
      ],
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.redisDatabaseHost,
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
  ]),
}
