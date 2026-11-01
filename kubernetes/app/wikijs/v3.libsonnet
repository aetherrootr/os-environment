local k8sUtils = import 'utils/k8s-utils.libsonnet';
local postgresBackup = import 'utils/postgres-backup.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'wikijs-v3',
  appReplicas:: 1,
  databaseHost:: $.appName + '-postgresdb',
  databaseName:: 'wiki',
  databaseUser:: 'wikijs',
  databasePasswordSecretName:: 'wikijs-postgresdb-secret',
  bootstrapSecretName:: 'wikijs-v3-bootstrap',
  dataSubPath:: 'wikijs_v3',

  local pvc = k8sUtils.getPVCName(namespace=$.namespace, storageClass='service-data'),
  local volume = {
    name: 'data',
    persistentVolumeClaim: { claimName: pvc },
  },
  local dbEnv = [
    k8sUtils.generateEnv('POSTGRES_DB', $.databaseName),
    k8sUtils.generateEnv('POSTGRES_USER', $.databaseUser),
    k8sUtils.generateSecretEnv('POSTGRES_PASSWORD', $.databasePasswordSecretName, 'password'),
  ],
  local db = k8sUtils.generateContainers(
    containerName='postgres',
    image='postgres:17-alpine',
    resources={
      requests: { cpu: '100m', memory: '256Mi' },
      limits: { cpu: '1000m', memory: '1Gi' },
    },
    env=dbEnv,
    ports=[k8sUtils.generateContainerPort(name='postgres', containerPort=5432)],
    volumeMounts=[
      k8sUtils.generateVolumeMount(name='data', mountPath='/var/lib/postgresql/data', subPath=$.dataSubPath + '/data'),
    ],
  ) + {
    readinessProbe: {
      exec: { command: ['pg_isready', '-U', $.databaseUser, '-d', $.databaseName] },
      initialDelaySeconds: 5,
      periodSeconds: 5,
    },
  },
  local app = k8sUtils.generateContainers(
    containerName='wikijs',
    image='ghcr.io/requarks/wiki:3.0.1',
    resources={
      requests: { cpu: '250m', memory: '512Mi' },
      limits: { cpu: '1000m', memory: '1536Mi' },
    },
    env=[
      k8sUtils.generateEnv('DB_HOST', $.databaseHost),
      k8sUtils.generateEnv('DB_PORT', '5432'),
      k8sUtils.generateEnv('DB_NAME', $.databaseName),
      k8sUtils.generateEnv('DB_USER', $.databaseUser),
      k8sUtils.generateEnv('DB_SCHEMA', 'wiki'),
      k8sUtils.generateEnv('DB_SSL', 'false'),
      k8sUtils.generateSecretEnv('DB_PASS', $.databasePasswordSecretName, 'password'),
      // Used only when initializing an empty database. Never use the upstream default password.
      k8sUtils.generateSecretEnv('ADMIN_EMAIL', $.bootstrapSecretName, 'email'),
      k8sUtils.generateSecretEnv('ADMIN_PASS', $.bootstrapSecretName, 'password'),
    ],
    ports=[k8sUtils.generateContainerPort(name='http', containerPort=3000)],
    volumeMounts=[
      k8sUtils.generateVolumeMount(name='data', mountPath='/wiki/data', subPath=$.dataSubPath + '/app'),
    ],
  ) + {
    startupProbe: {
      tcpSocket: { port: 'http' },
      periodSeconds: 5,
      failureThreshold: 60,
    },
    readinessProbe: {
      tcpSocket: { port: 'http' },
      periodSeconds: 5,
    },
  },
  local prepareData = k8sUtils.generateContainers(
    containerName='prepare-data',
    image='busybox:1.35.0',
    resources={
      requests: { cpu: '10m', memory: '16Mi' },
      limits: { cpu: '100m', memory: '32Mi' },
    },
    command=['sh', '-ec'],
    args=['mkdir -p /data/app; chown 1000:1000 /data/app; chmod 0700 /data/app'],
    volumeMounts=[k8sUtils.generateVolumeMount(name='data', mountPath='/data', subPath=$.dataSubPath)],
  ),
  local waitForDb = k8sUtils.generateContainers(
    containerName='wait-for-postgres',
    image='postgres:17-alpine',
    resources={
      requests: { cpu: '10m', memory: '16Mi' },
      limits: { cpu: '100m', memory: '32Mi' },
    },
    command=['sh', '-ec'],
    args=['until pg_isready -h ' + $.databaseHost + ' -U ' + $.databaseUser + ' -d ' + $.databaseName + '; do sleep 2; done'],
  ),
  local backup = postgresBackup {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  items: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.databaseHost,
      ports=[k8sUtils.generateServicePort(name='postgres', port=5432, targetPort=5432)],
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.databaseHost,
      containers=[db],
      podSpec=k8sUtils.generatePodSpec(volumes=[volume]),
    ),
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[k8sUtils.generateServicePort(name='http', port=3000, targetPort=3000)],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      replicas=$.appReplicas,
      containers=[app],
      podSpec=k8sUtils.generatePodSpec(volumes=[volume], initContainers=[prepareData, waitForDb]),
    ),
  ] + backup.cron,
}
