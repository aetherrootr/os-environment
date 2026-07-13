local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  databasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  schedule:: '30 3 * * *',

  local containerImage = 'postgres:17-alpine',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='POSTGRES_HOST', value=$.databaseHost),
    k8sUtils.generateEnv(name='POSTGRES_PORT', value=std.toString($.databasePort)),
    k8sUtils.generateEnv(name='POSTGRES_DB', value=$.databaseName),
    k8sUtils.generateEnv(name='POSTGRES_USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='PGPASSWORD', secretName=$.databasePasswordSecretName, key='password'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName + '-pg-backup',
    image=containerImage,
    command=['/bin/sh', '-c'],
    args=[
      'set -eu; mkdir -p /pg_backup; backup_file="/pg_backup/${POSTGRES_DB}-$(date +%Y%m%d%H%M%S).dump"; pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f "$backup_file"; find /pg_backup -type f -name "*.dump" -mtime +90 -delete',
    ],
    env=appEnv,
    resources={
      requests: {
        cpu: '50m',
        memory: '128Mi',
      },
      limits: {
        cpu: '500m',
        memory: '512Mi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/pg_backup',
        subPath=std.strReplace($.appName + '/pg_backup', '-', '_'),
      ),
    ],
  ),

  cron: std.prune([
    k8sUtils.generateCronJob(
      namespace=$.namespace,
      appName=$.appName + '-pg-backup',
      schedule=$.schedule,
      containers=containers,
      jobSpec=k8sUtils.generateCronJobSpec(
        appName=$.appName + '-pg-backup',
        podSpec=k8sUtils.generatePodSpec(
          volumes=[
            {
              name: $.appName + '-data-pvc',
              persistentVolumeClaim: {
                claimName: k8sUtils.getPVCName(
                  namespace=$.namespace,
                  storageClass='service-data',
                ),
              },
            },
          ],
        ),
      ),
    ),
  ]),
}
