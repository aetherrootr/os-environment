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
  port:: 3000,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName='wiki')],

  local containerImage = 'ghcr.io/requarks/wiki:3.0.1',
  local initContainerImage = 'busybox:1.35.0',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='DB_SCHEMA', value='wiki'),
    k8sUtils.generateEnv(name='DB_HOST', value=$.databaseHost),
    k8sUtils.generateEnv(name='DB_PORT', value=std.toString($.databasePort)),
    k8sUtils.generateEnv(name='DB_NAME', value=$.databaseName),
    k8sUtils.generateEnv(name='DB_USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='DB_PASS', secretName=$.databasePasswordSecretName, key='password'),
  ]),


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '250m',
        memory: '512Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1536Mi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/wiki/data',
        subPath=std.strReplace($.appName + '/app', '-', '_'),
      ),
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

  wikijs: std.prune([
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
        initContainers=[
          k8sUtils.generateContainers(
            containerName='prepare-data',
            image=initContainerImage,
            command=['sh', '-ec'],
            args=['mkdir -p /data/app; chown 1000:1000 /data/app; chmod 0700 /data/app'],
            resources={
              requests: { cpu: '10m', memory: '16Mi' },
              limits: { cpu: '100m', memory: '32Mi' },
            },
            volumeMounts=[
              k8sUtils.generateVolumeMount(
                name=$.appName + '-config-pvc',
                mountPath='/data',
                subPath=std.strReplace($.appName, '-', '_'),
              ),
            ],
          ),
          k8sUtils.generateContainers(
            containerName='wait-for-postgres',
            image='postgres:17-alpine',
            command=['sh', '-ec'],
            args=[
              |||
                until pg_isready "$@"; do sleep 2; done
                if [ "$(psql "$@" --no-password -XAtv ON_ERROR_STOP=1 -c 'SELECT EXISTS (SELECT 1 FROM wiki.users WHERE NOT "isSystem")')" != t ]; then
                  echo 'A migrated Wiki.js 3 database with existing users is required.' >&2
                  exit 1
                fi
              |||,
              '--', '-h', $.databaseHost,
              '-p', std.toString($.databasePort),
              '-U', $.databaseUser, '-d', $.databaseName,
            ],
            env=[
              k8sUtils.generateSecretEnv(name='PGPASSWORD', secretName=$.databasePasswordSecretName, key='password'),
            ],
            resources={
              requests: {
                cpu: '10m',
                memory: '16Mi',
              },
              limits: {
                cpu: '100m',
                memory: '32Mi',
              },
            },
          ),
        ],
      ),
      replicas=$.replicas,
    ) + {
      spec+: { strategy: { type: 'Recreate' } },
    },
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
