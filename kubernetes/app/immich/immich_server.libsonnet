local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  immichVersion:: error ('immichVersion is required'),
  postgresDatabaseHost:: error ('databaseHost is required'),
  postgresDatabasePort:: error ('databasePort is required'),
  postgresDatabaseName:: error ('databaseName is required'),
  postgresDatabaseUser:: error ('databaseUser is required'),
  postgresDatabasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  redisDatabaseHost:: error ('redisDatabaseHost is required'),
  redisDatabasePort:: error ('redisDatabasePort is required'),
  immichServerPort:: error ('immichServerPort is required'),
  replicas:: 1,

  local containerImage = "ghcr.io/immich-app/immich-server:" + $.immichVersion,
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],
  local certificateName = k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='DB_HOSTNAME', value=$.postgresDatabaseHost),
    k8sUtils.generateEnv(name='DB_PORT', value=std.toString($.postgresDatabasePort)),
    k8sUtils.generateEnv(name='DB_USERNAME', value=$.postgresDatabaseUser),
    k8sUtils.generateSecretEnv(name='DB_PASSWORD', secretName=$.postgresDatabasePasswordSecretName, key='password'),
    k8sUtils.generateEnv(name='DB_DATABASE_NAME', value=$.appName),
    k8sUtils.generateEnv(name='REDIS_HOSTNAME', value=$.redisDatabaseHost),
    k8sUtils.generateEnv(name='REDIS_PORT', value=std.toString($.redisDatabasePort)),
    k8sUtils.generateEnv(name='IMMICH_PORT', value=std.toString($.immichServerPort)),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.immichServerPort),
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
        name='localtime',
        mountPath='/etc/localtime',
        readOnly=true,
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
  ),

  immich_server: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.immichServerPort, targetPort=$.immichServerPort),
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
                storageClass='data1',
              ),
            },
          },
          k8sUtils.generateHostPathVolume(
            name='localtime',
            path='/etc/localtime',
            type='File',
          ),
        ],
      ),
      replicas=$.replicas,
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName,
      serviceName=$.appName,
      annotations={
        "nginx.ingress.kubernetes.io/proxy-body-size": "0",
        "nginx.ingress.kubernetes.io/proxy-request-buffering": "off",
        "nginx.ingress.kubernetes.io/proxy-buffering": "off",
        "nginx.ingress.kubernetes.io/proxy-read-timeout": "900",
        "nginx.ingress.kubernetes.io/proxy-send-timeout": "900",
        "nginx.ingress.kubernetes.io/enable-websocket": "true",
      },
      port=$.immichServerPort,
      hostnameList=hosts,
      certificateName=certificateName,
    ),
  ]),
}
