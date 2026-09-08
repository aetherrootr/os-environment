local k8sUtils = import 'k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: error 'appName is required',
  databasePaths:: error 'databasePaths is required',
  backupSubPath:: error 'backupSubPath is required',
  assert std.length($.databasePaths) > 0 : 'databasePaths must not be empty',
  runAsUser:: null,
  backupFileMode:: '0600',
  schedule:: '30 1 * * *',
  retentionDays:: 90,

  local containers = k8sUtils.generateContainers(
    containerName=$.appName + '-sqlite-backup',
    image='keinos/sqlite3:3.50.4',
    command=['/bin/sh', '-c'],
    args=[
      |||
        set -eu
        umask 077
        mkdir -p /sqlite_backup
        timestamp=$(date +%Y%m%d%H%M%S)
        rm -f /sqlite_backup/_SUCCESS
        trap 'rm -f /sqlite_backup/*.partial' EXIT

        while IFS= read -r database_path; do
          source="/media/service_data/$database_path"
          if [ ! -f "$source" ]; then
            echo "SQLite database does not exist: $source" >&2
            exit 1
          fi

          backup_name=$(printf '%s' "$database_path" | tr '/' '_')
          final="/sqlite_backup/${backup_name}-${timestamp}.backup"
          partial="${final}.partial"
          rm -f "$partial"
          echo "backing up $source to $final"
          sqlite3 -readonly "$source" ".timeout 30000" ".backup '$partial'"
          mv "$partial" "$final"
          chmod "$BACKUP_FILE_MODE" "$final"
        done <<EOF
        ${SQLITE_DATABASE_PATHS}
        EOF

        find /sqlite_backup -type f -name '*.backup' -exec chmod "$BACKUP_FILE_MODE" {} +
        find /sqlite_backup -type f -name '*.backup' -mtime "+${RETENTION_DAYS}" -delete
        printf '%s\n' "$timestamp" > /sqlite_backup/_SUCCESS.tmp
        mv /sqlite_backup/_SUCCESS.tmp /sqlite_backup/_SUCCESS
        chmod 0644 /sqlite_backup/_SUCCESS
        trap - EXIT
        echo "SQLite backups completed at $timestamp"
      |||,
    ],
    env=[
      k8sUtils.generateEnv(name='RETENTION_DAYS', value=std.toString($.retentionDays)),
      k8sUtils.generateEnv(name='TZ', value='CST-8'),
      k8sUtils.generateEnv(name='SQLITE_DATABASE_PATHS', value=std.join('\n', $.databasePaths)),
      k8sUtils.generateEnv(name='BACKUP_FILE_MODE', value=$.backupFileMode),
    ],
    resources={
      requests: { cpu: '50m', memory: '64Mi' },
      limits: { cpu: '500m', memory: '256Mi' },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(name='data', mountPath='/media/service_data', readOnly=true),
      k8sUtils.generateVolumeMount(
        name='data',
        mountPath='/sqlite_backup',
        subPath=$.backupSubPath,
      ),
    ],
  ) + if $.runAsUser == null then {} else {
    securityContext: {
      runAsUser: $.runAsUser,
    },
  },

  cron: [
    k8sUtils.generateCronJob(
      namespace=$.namespace,
      appName=$.appName + '-sqlite-backup',
      schedule=$.schedule,
      containers=containers,
      jobSpec=k8sUtils.generateCronJobSpec(
        appName=$.appName + '-sqlite-backup',
        concurrencyPolicy='Forbid',
        restartPolicy='Never',
        backoffLimit=2,
        failedJobsHistoryLimit=3,
        successfulJobsHistoryLimit=3,
        podSpec=k8sUtils.generatePodSpec(
          volumes=[
            {
              name: 'data',
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
        jobTemplate+: { spec+: { activeDeadlineSeconds: 1800 } },
      },
    ),
  ],
}
