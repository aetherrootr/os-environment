local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'authentik-proxy-outpost',
  port:: 9000,
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'ghcr.io/goauthentik/proxy:2025.6.2',

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='AUTHENTIK_HOST', value='https://authentik.corp.aetherrootr.com'),
    k8sUtils.generateEnv(name='AUTHENTIK_INSECURE', value='false'),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_TOKEN', secretName='authentik-secret', key='authentik-proxy-outpost-token'),

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
  ),

  authentikProxyOutpost: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
      ],
    ),
    k8sUtils.generateStatefulSet(
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
        'nginx.ingress.kubernetes.io/backend-protocol': 'HTTP',
      },
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),

}
