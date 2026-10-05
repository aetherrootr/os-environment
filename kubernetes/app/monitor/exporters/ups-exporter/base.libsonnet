local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 9995,

  local containerImage = 'hon95/prometheus-nut-exporter:1',

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '10m',
        memory: '32Mi',
      },
      limits: {
        cpu: '100m',
        memory: '64Mi',
      },
    },
    env=[
      k8sUtils.generateEnv(name='HTTP_PORT', value=std.toString($.port)),
      k8sUtils.generateEnv(name='HTTP_PATH', value='/metrics'),
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
