local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  authentikSecretName:: error ('authentikSecretKeySecretName is required'),
  redisDatabaseHost:: error ('databaseHost is required'),
  redisDatabasePort:: error ('databasePort is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  authentikHttpPort:: 9000,
  authentikMetricsPort:: 9300,

  serverReplicas:: 1,
  workerReplicas:: 2,

  local containerImage = 'ghcr.io/goauthentik/server:2025.6.2',

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local authentikEnv = std.prune([
    k8sUtils.generateSecretEnv(name='AUTHENTIK_SECRET_KEY', secretName=$.authentikSecretName, key='authentik-secret-key'),
    k8sUtils.generateEnv(name='AUTHENTIK_REDIS__HOST', value=$.redisDatabaseHost),
    k8sUtils.generateEnv(name='AUTHENTIK_REDIS__PORT', value=std.toString($.redisDatabasePort)),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_REDIS__PASSWORD', secretName=$.authentikSecretName, key='redis-password'),
    k8sUtils.generateEnv(name='AUTHENTIK_POSTGRESQL__HOST', value=$.databaseHost),
    k8sUtils.generateEnv(name='AUTHENTIK_POSTGRESQL__PORT', value=std.toString($.databasePort)),
    k8sUtils.generateEnv(name='AUTHENTIK_POSTGRESQL__NAME', value=$.databaseName),
    k8sUtils.generateEnv(name='AUTHENTIK_POSTGRESQL__USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_POSTGRESQL__PASSWORD', secretName=$.authentikSecretName, key='postgres-password'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__HOST', value='smtp.fastmail.com'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__PORT', value='465'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__USERNAME', value='aether@aetherroootr.com'),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_EMAIL__PASSWORD', secretName=$.authentikSecretName, key='email-password'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__USE_SSL', value='true'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__TIMEOUT', value='30'),
    k8sUtils.generateEnv(name='AUTHENTIK_EMAIL__FROM', value='authentik <authentik@aetherrootr.com>'),
  ]),

  local serverContainer = k8sUtils.generateContainers(
    containerName=$.appName + '-server',
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.authentikHttpPort),
      k8sUtils.generateContainerPort(name='metrics', containerPort=$.authentikMetricsPort),
    ],
    args=['server'],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '500m',
        memory: '1Gi',
      },
    },
    env=authentikEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/media',
        subPath=std.strReplace($.appName + '/media', '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/templates',
        subPath=std.strReplace($.appName + '/custom-templates', '-', '_'),
      ),
    ],
  ),

  local workerContainer = k8sUtils.generateContainers(
    containerName=$.appName + '-worker',
    image=containerImage,
    args=['worker'],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '1500m',
        memory: '2Gi',
      },
    },
    env=authentikEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/media',
        subPath=std.strReplace($.appName + '/media', '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/templates',
        subPath=std.strReplace($.appName + '/custom-templates', '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/certs',
        subPath=std.strReplace($.appName + '/certs', '-', '_'),
      ),
    ],
  ),

  authentik: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName + '-server',
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.authentikHttpPort, targetPort=$.authentikHttpPort),
        k8sUtils.generateServicePort(name='metrics', port=$.authentikMetricsPort, targetPort=$.authentikMetricsPort),
      ],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName + '-server',
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
        serviceAccountName=$.appName,
      ),
      containers=serverContainer,
      replicas=$.serverReplicas,
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName + '-worker',
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
        serviceAccountName=$.appName,
      ),
      containers=workerContainer,
      replicas=$.workerReplicas,
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName + '-server',
      serviceName=$.appName + '-server',
      annotations={},
      port=$.authentikHttpPort,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
