local k8sUtils = import 'utils/k8s-utils.libsonnet';
local sqliteBackup = import 'utils/sqlite-backup.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 5244,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'openlistteam/openlist:v4.1.9-aio',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '128Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1Gi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/opt/openlist/data',
        subPath=$.appName,
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/var/storage/local_storage',
        subPath=$.appName,
      ),
    ],
    env=[
      k8sUtils.generateEnv('UMASK', '022'),
    ]
  ) + {
    securityContext: {
      runAsUser: 0,
      runAsGroup: 0,
    },
  },

  local sqliteBackupResources = sqliteBackup {
    namespace: $.namespace,
    appName: $.appName,
    databasePaths: ['openlist/data.db'],
    backupSubPath: 'openlist/sqlite_backup',
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
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
            name: $.appName + '-data-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='data0',
              ),
            },
          },
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
        'nginx.ingress.kubernetes.io/proxy-body-size': '0',
        'nginx.ingress.kubernetes.io/proxy-request-buffering': 'off',
      },
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ] + sqliteBackupResources.cron),
}
