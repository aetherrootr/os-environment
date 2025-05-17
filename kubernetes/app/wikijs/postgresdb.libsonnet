local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  databasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'postgres:15-alpine',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='POSTGRES_DB', value=$.databaseName),
    k8sUtils.generateEnv(name='POSTGRES_USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='POSTGRES_PASSWORD', secretName=$.databasePasswordSecretName, key='password'),
  ]),


  local containers = k8sUtils.generateContainers(
    containerName=$.databaseName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.databasePort),
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
        mountPath='/var/lib/postgresql/data',
        subPath=std.strReplace($.appName + '/data', '-', '_'),
      ),
    ],
  ),

  postgresdb: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.databaseHost,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.databasePort, targetPort=$.databasePort),
      ],
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.databaseHost,
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
