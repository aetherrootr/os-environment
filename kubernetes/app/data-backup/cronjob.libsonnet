local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  config:: error 'config is required',
  local c = $.config,
  local containers = k8sUtils.generateContainers(
    containerName=c.appName,
    image='rclone/rclone:1.73.4',
    command=['/bin/sh', '/scripts/backup.sh'],
    env=[
      k8sUtils.generateEnv(name='RETENTION_DAYS', value=std.toString(c.retentionDays)),
      k8sUtils.generateEnv(name='RCLONE_CONFIG', value='/media/service_data/data-backup/rclone.conf'),
    ],
    resources={
      requests: { cpu: '100m', memory: '128Mi' },
      limits: { cpu: '1', memory: '512Mi' },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(name='data', mountPath='/media/service_data', readOnly=true),
      // Writable directory lets rclone persist refreshed OAuth tokens.
      k8sUtils.generateVolumeMount(name='data', mountPath='/media/service_data/data-backup', subPath='data-backup'),
      k8sUtils.generateVolumeMount(name='scripts', mountPath='/scripts', readOnly=true),
    ],
  ),

  cron: k8sUtils.generateCronJob(
    namespace=c.namespace,
    appName=c.appName,
    schedule=c.schedule,
    containers=containers,
    jobSpec=k8sUtils.generateCronJobSpec(
      appName=c.appName,
      timeZone='Asia/Shanghai',
      suspend=c.suspend,
      concurrencyPolicy='Forbid',
      restartPolicy='Never',
      backoffLimit=3,
      successfulJobsHistoryLimit=7,
      failedJobsHistoryLimit=7,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: 'data',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(namespace=c.namespace, storageClass='service-data'),
            },
          },
          k8sUtils.generateConfigMapVolume(name='scripts', configMapName=c.appName),
        ],
      ),
    ) + {
      // Total Job duration, including all Pod retries.
      jobTemplate+: { spec+: { activeDeadlineSeconds: 21600 } },
    },
  ),
}
