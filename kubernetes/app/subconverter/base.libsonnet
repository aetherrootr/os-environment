local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 25500,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'metacubex/subconverter@sha256:15340b0415466e2e3cb01c5b9b9fe6adf77e094f6ba703ba56271afb761dad29',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '128Mi',
      },
      limits: {
        cpu: '500m',
        memory: '256Mi',
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
      annotations={
        'nginx.ingress.kubernetes.io/rewrite-target': '/sub',
      },
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
      extraPaths=[],
      extraGeneratedPaths=[
        k8sUtils.generateIngressPath(
          urlPath='/',
          serviceName=$.appName,
          servicePort=$.port,
          pathType='Prefix',
        ),
      ],
    ),
  ]),
}
