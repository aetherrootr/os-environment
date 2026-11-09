local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: error 'appName is required',
  databaseHost:: error 'databaseHost is required',
  databasePort:: error 'databasePort is required',
  databaseName:: error 'databaseName is required',
  databaseUser:: error 'databaseUser is required',
  databasePasswordSecretName:: error 'databasePasswordSecretName is required',

  local containers = k8sUtils.generateContainers(
    containerName='install',
    image='ghcr.io/aetherrootr/open-webui-zen-billing:v0.1.0',
    env=[
      k8sUtils.generateEnv('WEBUI_INTERNAL_URL', 'http://' + $.appName + ':8080'),
      k8sUtils.generateEnv('WEBUI_SECRET_KEY_FILE', '/app/backend/data/.webui_secret_key'),
      k8sUtils.generateSecretEnv('DATABASE_PASSWORD', $.databasePasswordSecretName, 'password'),
      k8sUtils.generateEnv('DATABASE_URL', 'postgresql://' + $.databaseUser + ':$(DATABASE_PASSWORD)@' + $.databaseHost + ':' + std.toString($.databasePort) + '/' + $.databaseName),
    ],
    resources={
      requests: { cpu: '100m', memory: '256Mi' },
      limits: { cpu: '1000m', memory: '1Gi' },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name='data',
        mountPath='/app/backend/data',
        subPath=$.appName,
        readOnly=true,
      ),
    ],
  ),

  zenBillJob: std.prune([
    k8sUtils.generateJob(
      namespace=$.namespace,
      appName=$.appName + '-install-zen-billing',
      extraLabels={ app: $.appName + '-billing-installer' },
      containers=containers,
      backoffLimit=2,
      activeDeadlineSeconds=600,
      annotations={
        'argocd.argoproj.io/hook': 'PostSync',
        'argocd.argoproj.io/hook-delete-policy': 'BeforeHookCreation,HookSucceeded',
      },
      podSpec=k8sUtils.generatePodSpec(
        restartPolicy='Never',
        volumes=[{
          name: 'data',
          persistentVolumeClaim: {
            claimName: k8sUtils.getPVCName(namespace=$.namespace, storageClass='service-data'),
          },
        }],
      ),
    ),
  ]),
}
