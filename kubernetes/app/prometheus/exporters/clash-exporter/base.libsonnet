local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 2112,

  local containerImage = 'zzde/clash-exporter:latest',

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
    command=[
      '/app/clash-exporter',
      '-collectTracing=false',
      '-collectDest=true',
    ],
    env=[
      k8sUtils.generateEnv(name='CLASH_HOST', value='192.168.8.1:9090'),
      k8sUtils.generateSecretEnv(name='CLASH_TOKEN', secretName='prometheus-clash-exporter-secret', key='token'),
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
