local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  config:: error 'config is required',
  local c = $.config,
  local dataVolume = {
    name: 'data',
    persistentVolumeClaim: {
      claimName: k8sUtils.getPVCName(namespace=c.namespace, storageClass='service-data'),
    },
  },
  local commonMounts = [
    k8sUtils.generateVolumeMount(name='data', mountPath='/media/service_data', readOnly=true),
    // Writable directory lets rclone persist refreshed OAuth tokens.
    k8sUtils.generateVolumeMount(name='data', mountPath='/media/service_data/data-backup', subPath='data-backup'),
    k8sUtils.generateVolumeMount(name='scripts', mountPath='/scripts', readOnly=true),
  ],
  local commonEnv = [
    k8sUtils.generateEnv(name='RCLONE_CONFIG', value='/media/service_data/data-backup/rclone.conf'),
    // Keep the v2 layout separate from the legacy date directories.
    k8sUtils.generateEnv(name='REMOTE_ROOT', value='onedrive:/backup/kubernetes-daily/v2'),
    k8sUtils.generateEnv(name='MAX_DELETE', value='10000'),
  ],
  local backupContainers = k8sUtils.generateContainers(
    containerName=c.appName,
    image='rclone/rclone:1.73.4',
    command=['/bin/sh', '/scripts/backup.sh'],
    env=commonEnv + [
      k8sUtils.generateEnv(name='PATH_CONCURRENCY', value='3'),
      k8sUtils.generateEnv(name='DATABASE_READY_TIMEOUT', value='3600'),
    ],
    resources={
      requests: { cpu: '250m', memory: '256Mi' },
      limits: { cpu: '2', memory: '1Gi' },
    },
    volumeMounts=commonMounts + [k8sUtils.generateVolumeMount(name='config', mountPath='/config', readOnly=true)],
  ),
  local snapshotContainers = k8sUtils.generateContainers(
    containerName=c.appName + '-snapshot',
    image='rclone/rclone:1.73.4',
    command=['/bin/sh', '/scripts/snapshot.sh'],
    env=commonEnv + [
      k8sUtils.generateEnv(name='RETENTION_DAYS', value=std.toString(c.snapshotRetentionDays)),
      k8sUtils.generateEnv(name='LATEST_READY_TIMEOUT', value='10800'),
    ],
    resources={
      requests: { cpu: '100m', memory: '128Mi' },
      limits: { cpu: '1', memory: '512Mi' },
    },
    volumeMounts=commonMounts,
  ),

  cron: k8sUtils.generateCronJob(
    namespace=c.namespace,
    appName=c.appName,
    schedule=c.schedule,
    containers=backupContainers,
    jobSpec=k8sUtils.generateCronJobSpec(
      appName=c.appName,
      timeZone='Asia/Shanghai',
      suspend=c.suspend,
      concurrencyPolicy='Forbid',
      restartPolicy='Never',
      backoffLimit=1,
      successfulJobsHistoryLimit=7,
      failedJobsHistoryLimit=7,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          dataVolume,
          k8sUtils.generateConfigMapVolume(
            name='scripts',
            configMapName=c.appName,
            items=[k8sUtils.generateVolumeItem(key='backup.sh', path='backup.sh')],
          ),
          k8sUtils.generateConfigMapVolume(
            name='config',
            configMapName=c.appName,
            items=[k8sUtils.generateVolumeItem(key='paths', path='paths')],
          ),
        ],
      ) + { terminationGracePeriodSeconds: 120 },
    ) + {
      // Leave a four-hour gap before the next 02:00 schedule. The stable latest
      // directory makes an interrupted transfer resumable by the next Job.
      jobTemplate+: { spec+: { activeDeadlineSeconds: 72000 } },
    },
  ),

  snapshotCron: k8sUtils.generateCronJob(
    namespace=c.namespace,
    appName=c.appName + '-weekly-snapshot',
    schedule=c.snapshotSchedule,
    containers=snapshotContainers,
    jobSpec=k8sUtils.generateCronJobSpec(
      appName=c.appName + '-weekly-snapshot',
      timeZone='Asia/Shanghai',
      suspend=c.suspend,
      concurrencyPolicy='Forbid',
      restartPolicy='Never',
      backoffLimit=1,
      successfulJobsHistoryLimit=8,
      failedJobsHistoryLimit=8,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          dataVolume,
          k8sUtils.generateConfigMapVolume(
            name='scripts',
            configMapName=c.appName,
            items=[k8sUtils.generateVolumeItem(key='snapshot.sh', path='snapshot.sh')],
          ),
        ],
      ) + { terminationGracePeriodSeconds: 120 },
    ) + {
      jobTemplate+: { spec+: { activeDeadlineSeconds: c.snapshotDeadlineSeconds } },
    },
  ),
}
