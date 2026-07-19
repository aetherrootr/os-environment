local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  authentikTokenSecretName:: error ('authentikTokenSecretName is required'),
  port:: 9000,
  replicas:: 1,

  local containerImage = 'ghcr.io/goauthentik/proxy:2026.5.5',
  
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='AUTHENTIK_HOST', value='http://authentik-server.infrastructure.svc.cluster.local:9000'),
    k8sUtils.generateEnv(name='AUTHENTIK_HOST_BROWSER', value='https://authentik.aetherrootr.com'),
    k8sUtils.generateEnv(name='AUTHENTIK_INSECURE', value='false'),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_TOKEN', secretName=$.authentikTokenSecretName, key='authentik-proxy-outpost-token'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '50m',
        memory: '128Mi',
      },
      limits: {
        cpu: '100m',
        memory: '256Mi',
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
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(),
      replicas=$.replicas,
    ),
  ]),
}
