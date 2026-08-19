local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  appSecretName:: error ('appSecretName is required'),
  port:: 8000,
  
  local containerImage = 'ghcr.io/open-webui/open-terminal:0.11.35',

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    imagePullPolicy='Always',
    ports=[k8sUtils.generateContainerPort(name='http', containerPort=$.port)],
    resources={
      requests: { cpu: '100m', memory: '256Mi' },
      limits: { cpu: '2000m', memory: '4Gi' },
    },
    env=[
      k8sUtils.generateSecretEnv(
        name='OPEN_TERMINAL_API_KEY',
        secretName=$.appSecretName,
        key='open-terminal-api-key',
      ),
    ],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data',
        mountPath='/home/user',
      ),
    ],
  ),

  openTerminal: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port)],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[{
          name: $.appName + '-data',
          emptyDir: {
            sizeLimit: '10Gi',
          },
        }],
      ),
    ) + {
      spec+: { strategy: { type: 'Recreate' } },
    },
  ]),
}
