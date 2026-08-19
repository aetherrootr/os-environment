local k8sUtils = import 'utils/k8s-utils.libsonnet';
local settings = importstr 'config/settings.yml';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 8080,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],
  local containerImage='searxng/searxng:2026.8.19-5ffd32ca2',

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    command=['/bin/sh', '-c'],
    args=[
      'export SEARXNG_SECRET="$(head -c 32 /dev/urandom | base64)" && exec /usr/local/searxng/entrypoint.sh',
    ],
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
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
    env=[
      k8sUtils.generateEnv(name='SEARXNG_BASE_URL', value='https://' + hosts[0] + '/'),
      k8sUtils.generateEnv(name='SEARXNG_PORT', value=std.toString($.port)),
      k8sUtils.generateEnv(name='FORCE_OWNERSHIP', value='false'),
    ],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name='config',
        mountPath='/etc/searxng/settings.yml',
        subPath='settings.yml',
        readOnly=true,
      ),
    ],
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'settings.yml': settings,
      },
    ),
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
          k8sUtils.generateConfigMapVolume(
            name='config',
            configMapName=$.appName,
            items=[
              k8sUtils.generateVolumeItem(key='settings.yml', path='settings.yml'),
            ],
          ),
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
