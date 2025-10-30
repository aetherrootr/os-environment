local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  appName:: error ('appName is required'),
  namespace:: error ('namespace is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  appSecretName:: error ('appSecretName is required'),
  port:: 8080,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  replicas:: 1,

  local hosts = [k8sUtils.getServiceHostname(serviceName='finance')],

  local containerImage = 'fireflyiii/core:version-6.4.2',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='APP_ENV', value='production'),
    k8sUtils.generateEnv(name='APP_DEBUG', value='false'),
    k8sUtils.generateEnv(name='SITE_OWNER', value='aether@aetherrootr.com'),
    k8sUtils.generateSecretEnv(name='APP_KEY', secretName=$.appSecretName, key='app-key'),
    k8sUtils.generateEnv(name='DEFAULT_LANGUAGE', value='zh_CN'),
    k8sUtils.generateEnv(name='DEFAULT_LOCALE', value='equal'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
    k8sUtils.generateEnv(name='LOG_CHANNEL', value='stack'),
    k8sUtils.generateEnv(name='APP_LOG_LEVEL', value='notice'),
    k8sUtils.generateEnv(name='AUDIT_LOG_LEVEL', value='emergency'),
    k8sUtils.generateEnv(name='DB_CONNECTION', value='pgsql'),
    k8sUtils.generateEnv(name='DB_HOST', value=$.databaseHost),
    k8sUtils.generateEnv(name='DB_PORT', value=std.toString($.databasePort)),
    k8sUtils.generateEnv(name='DB_DATABASE', value=$.databaseName),
    k8sUtils.generateEnv(name='DB_USERNAME', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='DB_PASSWORD', secretName=$.appSecretName, key='db-password'),
    k8sUtils.generateEnv(name='CACHE_DRIVER', value='file'),
    k8sUtils.generateEnv(name='SESSION_DRIVER', value='file'),
    k8sUtils.generateEnv(name='COOKIE_PATH', value='/'),
    k8sUtils.generateEnv(name='COOKIE_SECURE', value='true'),
    k8sUtils.generateEnv(name='COOKIE_SAMESITE', value='lax'),
    k8sUtils.generateEnv(name='ENABLE_EXCHANGE_RATES', value='true'),
    k8sUtils.generateEnv(name='MAP_DEFAULT_LAT', value='116.417798'),
    k8sUtils.generateEnv(name='MAP_DEFAULT_LONG', value='39.908802'),
    k8sUtils.generateEnv(name='MAP_DEFAULT_ZOOM', value='6'),
    k8sUtils.generateEnv(name='AUTHENTICATION_GUARD', value='web'),
    k8sUtils.generateEnv(name='DISABLE_FRAME_HEADER', value='false'),
    k8sUtils.generateEnv(name='DISABLE_CSP_HEADER', value='false'),
    k8sUtils.generateSecretEnv(name='STATIC_CRON_TOKEN', secretName=$.appSecretName, key='static-cron-token'),
    k8sUtils.generateEnv(name='APP_NAME', value='FireflyIII'),
    k8sUtils.generateEnv(name='BROADCAST_DRIVER', value='log'),
    k8sUtils.generateEnv(name='QUEUE_DRIVER', value='sync'),
    k8sUtils.generateEnv(name='CACHE_PREFIX', value='firefly'),
    k8sUtils.generateEnv(name='USE_RUNNING_BALANCE', value='false'),
    k8sUtils.generateEnv(name='FIREFLY_III_LAYOUT', value='v1'),
    k8sUtils.generateEnv(name='QUERY_PARSER_IMPLEMENTATION', value='new'),
    k8sUtils.generateEnv(name='APP_URL', value='https://' + hosts[0]),
    k8sUtils.generateEnv(name='TRUSTED_PROXIES', value='**'),

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
        name=$.appName + '-data-pvc',
        mountPath='/var/www/html/storage/upload',
        subPath=std.strReplace($.appName + '/firefly-iii', '-', '_'),
      ),
    ],
  ),

  core: std.prune([
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
