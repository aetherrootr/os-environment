local k8sUtils = import 'k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: error 'appName is required',
  databaseHost:: error 'databaseHost is required',
  databasePort:: 5432,
  databaseName:: error 'databaseName is required',
  databaseUser:: error 'databaseUser is required',
  databasePasswordSecretName:: error 'databasePasswordSecretName is required',
  databasePasswordSecretKey:: 'password',
  schedule:: '0 1 * * *',
  retentionDays:: 90,
  backupSubPath:: std.strReplace($.appName + '/pg_backup', '-', '_'),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName + '-pg-backup',
    image='postgres:17-alpine',
    command=['/bin/sh', '-c'],
    args=[
      |||
        set -eu
        umask 077
        mkdir -p /pg_backup
        timestamp=$(date +%Y%m%d%H%M%S)
        final="/pg_backup/${POSTGRES_DB}-${timestamp}.dump"
        partial="${final}.partial"
        rm -f /pg_backup/_SUCCESS
        trap 'rm -f "$partial"' EXIT
        pg_dump --no-password -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f "$partial"
        mv "$partial" "$final"
        printf '%s\n' "$timestamp" > /pg_backup/_SUCCESS.tmp
        mv /pg_backup/_SUCCESS.tmp /pg_backup/_SUCCESS
        find /pg_backup -type f -name '*.dump' -mtime "+${RETENTION_DAYS}" -delete
        trap - EXIT
      |||,
    ],
    env=[
      k8sUtils.generateEnv(name='POSTGRES_HOST', value=$.databaseHost),
      k8sUtils.generateEnv(name='POSTGRES_PORT', value=std.toString($.databasePort)),
      k8sUtils.generateEnv(name='POSTGRES_DB', value=$.databaseName),
      k8sUtils.generateEnv(name='POSTGRES_USER', value=$.databaseUser),
      k8sUtils.generateSecretEnv(
        name='PGPASSWORD',
        secretName=$.databasePasswordSecretName,
        key=$.databasePasswordSecretKey,
      ),
      k8sUtils.generateEnv(name='RETENTION_DAYS', value=std.toString($.retentionDays)),
      // POSIX fixed UTC+8 notation does not depend on tzdata in Alpine images.
      k8sUtils.generateEnv(name='TZ', value='CST-8'),
    ],
    resources={
      requests: { cpu: '50m', memory: '128Mi' },
      limits: { cpu: '500m', memory: '512Mi' },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name='backup-data',
        mountPath='/pg_backup',
        subPath=$.backupSubPath,
      ),
    ],
  ),

  cron: [
    k8sUtils.generateCronJob(
      namespace=$.namespace,
      appName=$.appName + '-pg-backup',
      schedule=$.schedule,
      containers=containers,
      jobSpec=k8sUtils.generateCronJobSpec(
        appName=$.appName + '-pg-backup',
        concurrencyPolicy='Forbid',
        restartPolicy='Never',
        backoffLimit=2,
        failedJobsHistoryLimit=3,
        successfulJobsHistoryLimit=3,
        podSpec=k8sUtils.generatePodSpec(
          volumes=[
            {
              name: 'backup-data',
              persistentVolumeClaim: {
                claimName: k8sUtils.getPVCName(
                  namespace=$.namespace,
                  storageClass='service-data',
                ),
              },
            },
          ],
        ),
      ) + {
        jobTemplate+: { spec+: { activeDeadlineSeconds: 3600 } },
      },
    ),
  ],
}
