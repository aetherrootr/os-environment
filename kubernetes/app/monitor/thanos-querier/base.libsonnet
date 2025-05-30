local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 9090,
  grpcPort:: 10901,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'thanosio/thanos:v0.38.0',
  local hosts = [k8sUtils.getServiceHostname(serviceName='prometheus')],

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
      k8sUtils.generateContainerPort(name='grpc', containerPort=$.grpcPort),
    ],
    args=[
      'query',
      '--http-address=0.0.0.0:' + std.toString($.port),
      '--grpc-address=0.0.0.0:' + std.toString($.grpcPort),
      '--endpoint=prometheus-homeassistant.infrastructure.svc.cluster.local:10901',
      '--endpoint=prometheus-common.infrastructure.svc.cluster.local:10901',
      '--query.timeout=5m',
      '--query.max-concurrent-select=2',
      ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '2000m',
        memory: '1Gi',
      },
    },
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
