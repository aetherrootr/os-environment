local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 8090,

  local containerImage = 'ghcr.io/martabal/qbittorrent-exporter:latest',

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
    env=[
      k8sUtils.generateEnv(name='QBITTORRENT_BASE_URL', value='https://torrent.corp.aetherrootr.com/'),
      k8sUtils.generateSecretEnv(name='QBITTORRENT_USERNAME', secretName='prometheus-qbittorrent-exporter-secret', key='username'),
      k8sUtils.generateSecretEnv(name='QBITTORRENT_PASSWORD', secretName='prometheus-qbittorrent-exporter-secret', key='password'),
    ]
  ),

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
      podSpec=k8sUtils.generatePodSpec(),
      replicas=$.replicas,
    ),
  ]),
}
