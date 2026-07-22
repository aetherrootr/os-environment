local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8080,

  redisDatabaseHost:: error ('redisDatabaseHost is required'),
  redisDatabasePort:: error ('redisDatabasePort is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  databasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  appSecretName:: error ('appSecretName is required'),

  image:: 'ghcr.io/aetherrootr/ani-tracker:v0.1.8',
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  replicas:: 1,
  workerReplicas:: 1,
  beatReplicas:: 1,

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],
  local databaseUrl = 'postgresql+psycopg://' + $.databaseUser + ':$(POSTGRES_PASSWORD)@' + $.databaseHost + ':' + std.toString($.databasePort) + '/' + $.databaseName,

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='APP_PORT', value=std.toString($.port)),
    k8sUtils.generateEnv(name='CORS_ORIGIN', value='https://' + hosts[0]),
    k8sUtils.generateSecretEnv(name='SECRET_KEY', secretName=$.appSecretName, key='secret-key'),
    k8sUtils.generateEnv(name='POSTGRES_DB', value=$.databaseName),
    k8sUtils.generateEnv(name='POSTGRES_USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='POSTGRES_PASSWORD', secretName=$.databasePasswordSecretName, key='password'),
    k8sUtils.generateEnv(name='DATABASE_URL', value=databaseUrl),
    k8sUtils.generateEnv(name='CELERY_BROKER_URL', value='redis://' + $.redisDatabaseHost + ':' + std.toString($.redisDatabasePort) + '/0'),
    k8sUtils.generateEnv(name='CELERY_RESULT_BACKEND', value='redis://' + $.redisDatabaseHost + ':' + std.toString($.redisDatabasePort) + '/1'),
    k8sUtils.generateEnv(name='ANIME_TRACKER_INSTANCE_PATH', value='/var/lib/ani-tracker'),
    k8sUtils.generateEnv(name='SESSION_COOKIE_SAMESITE', value='Lax'),
    k8sUtils.generateEnv(name='WEB_CONCURRENCY', value='2'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
    k8sUtils.generateSecretEnv(name='TMDB_API_KEY', secretName=$.appSecretName, key='tmdb-api-key'),
    k8sUtils.generateEnv(name='TMDB_INCLUDE_ADULT', value='false'),
    k8sUtils.generateSecretEnv(name='TVDB_API_KEY', secretName=$.appSecretName, key='tvdb-api-key'),
    k8sUtils.generateSecretEnv(name='TVDB_PIN', secretName=$.appSecretName, key='tvdb-pin'),
    k8sUtils.generateEnv(name='OIDC_ENABLED', value='true'),
    k8sUtils.generateEnv(name='OIDC_ISSUER', value='https://authentik.aetherrootr.com/application/o/ani-tracker/'),
    k8sUtils.generateEnv(name='OIDC_CLIENT_ID', value='S65u8uf3NpVOHPQt4rWX5LTmwGxQFoXt7r1gSk45'),
    k8sUtils.generateSecretEnv(name='OIDC_CLIENT_SECRET', secretName=$.appSecretName, key='oidc-client-secret'),
    k8sUtils.generateEnv(name='OIDC_SCOPE', value='openid email profile'),
    k8sUtils.generateEnv(name='IMPORT_PROVIDER_TIMEOUT', value='10'),
    k8sUtils.generateEnv(name='IMPORT_SEARCH_TIMEOUT', value='120'),
    k8sUtils.generateEnv(name='GUNICORN_TIMEOUT', value='1000'),
    k8sUtils.generateEnv(name='AUTO_IMPORT_TVDB_SEASONS_ENABLED', value='true'),
    k8sUtils.generateEnv(name='AUTO_IMPORT_BANGUMI_RELATED_ANIME_ENABLED', value='true'),
    k8sUtils.generateEnv(name='APP_FAVICON_FILE', value='/opt/ani-tracker/branding/favicon.ico'),
    k8sUtils.generateEnv(name='APP_PWA_ICON_192_FILE', value='/opt/ani-tracker/branding/icon-192x192.png'),
    k8sUtils.generateEnv(name='APP_PWA_ICON_512_FILE', value='/opt/ani-tracker/branding/icon-512x512.png'),
    k8sUtils.generateEnv(name='APP_PWA_ICON_MASKABLE_FILE', value='/opt/ani-tracker/branding/icon-maskable-512x512.png'),
    k8sUtils.generateEnv(name='APP_APPLE_TOUCH_ICON_FILE', value='/opt/ani-tracker/branding/apple-touch-icon.png'),
    k8sUtils.generateEnv(name='USER_WALLPAPER_MAX_IMAGES_PER_USER', value='50'),
    k8sUtils.generateEnv(name='USER_WALLPAPER_MAX_BYTES', value='104857600')
  ]),

  local waitForPostgresContainer = k8sUtils.generateContainers(
    containerName='wait-for-postgres',
    image='postgres:17-alpine',
    command=['sh', '-c'],
    args=[
      'until pg_isready -h ' + $.databaseHost + ' -p ' + std.toString($.databasePort) + ' -U ' + $.databaseUser + ' -d ' + $.databaseName + '; do sleep 2; done',
    ],
    resources={
      requests: {
        cpu: '10m',
        memory: '32Mi',
      },
      limits: {
        cpu: '100m',
        memory: '128Mi',
      },
    },
  ),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=$.image,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        memory: '10Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/var/lib/ani-tracker',
        subPath=std.strReplace($.appName + '/' + $.appName, '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/opt/ani-tracker/branding',
        readOnly=true,
        subPath=std.strReplace($.appName + '/branding', '-', '_'),
      ),
    ],
  ),

  local workerContainers = k8sUtils.generateContainers(
    containerName=$.appName + '-worker',
    image=$.image,
    command=['python', '/opt/ani-tracker/backend/ani-tracker.pyz'],
    args=[
      'worker',
      '--loglevel',
      'info',
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        memory: '10Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/var/lib/ani-tracker',
        subPath=std.strReplace($.appName + '/' + $.appName, '-', '_'),
      ),
    ],
  ),

  local beatContainers = k8sUtils.generateContainers(
    containerName=$.appName + '-beat',
    image=$.image,
    command=['python', '/opt/ani-tracker/backend/ani-tracker.pyz'],
    args=[
      'beat',
      '--loglevel',
      'info',
      '--schedule',
      '/var/lib/ani-tracker/celerybeat-schedule',
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        memory: '10Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/var/lib/ani-tracker',
        subPath=std.strReplace($.appName + '/' + $.appName, '-', '_'),
      ),
    ],
  ),

  aniTracker: std.prune([
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
        initContainers=[waitForPostgresContainer],
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
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName + '-worker',
      containers=workerContainers,
      podSpec=k8sUtils.generatePodSpec(
        initContainers=[waitForPostgresContainer],
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
      replicas=$.workerReplicas,
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName + '-beat',
      containers=beatContainers,
      podSpec=k8sUtils.generatePodSpec(
        initContainers=[waitForPostgresContainer],
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
      replicas=$.beatReplicas,
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
