local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  appName:: error ('appName is required'),
  namespace:: error ('namespace is required'),
  appSecretName:: error ('appSecretName is required'),
  replicas:: 1,
  schedule:: '0 3 * * *',

  local containerImage = 'alpine:3.20',

  local appEnv = std.prune([
    k8sUtils.generateSecretEnv(name='STATIC_CRON_TOKEN', secretName=$.appSecretName, key='static-cron-token'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName + '-cronjob',
    image=containerImage,
    command=['/bin/sh', '-c'],
    args=[
      'wget -O- https://' + k8sUtils.getServiceHostname(serviceName='finance') +'/api/v1/cron/$STATIC_CRON_TOKEN',
    ],
    env=appEnv,
    resources={
      requests: {
        cpu: '10m',
        memory: '32Mi',
      },
      limits: {
        cpu: '100m',
        memory: '128Mi',
      },
    },
  ),

  cron: std.prune([
    k8sUtils.generateCronJob(
      namespace=$.namespace,
      appName=$.appName + '-cronjob',
      schedule=$.schedule,
      containers=containers,
      jobSpec=k8sUtils.generateCronJobSpec(
        appName=$.appName + '-cronjob',
        podSpec=k8sUtils.generatePodSpec(),
      ),
    ),
  ]),
}
