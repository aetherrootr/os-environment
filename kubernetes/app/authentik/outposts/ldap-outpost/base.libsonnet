local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,

  local containerImage = 'ghcr.io/goauthentik/ldap:2025.8.1',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='AUTHENTIK_HOST', value='https://authentik.corp.aetherrootr.com'),
    k8sUtils.generateEnv(name='AUTHENTIK_INSECURE', value='false'),
    k8sUtils.generateSecretEnv(name='AUTHENTIK_TOKEN', secretName='authentik-ldap-outpost-secret', key='authentik-ldap-outpost-token'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='ldap', containerPort=3389),
      k8sUtils.generateContainerPort(name='ldaps', containerPort=6636),
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
        k8sUtils.generateServicePort(name='ldap', port=3389, targetPort=3389),
        k8sUtils.generateServicePort(name='ldaps', port=6636, targetPort=6636),
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
