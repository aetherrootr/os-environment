local cronjob = import 'cronjob.libsonnet';
local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'data-backup',
  schedule:: '0 2 * * *',
  snapshotSchedule:: '0 3 * * 0',
  snapshotDeadlineSeconds:: 79200,
  suspend:: false,
  snapshotRetentionDays:: 56,

  apiVersion: 'v1',
  kind: 'List',
  items: [
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'backup.sh': importstr 'scripts/backup.sh',
        'snapshot.sh': importstr 'scripts/snapshot.sh',
        paths: import 'paths.libsonnet',
      },
    ),
    (cronjob { config:: $ }).cron,
    (cronjob { config:: $ }).snapshotCron,
  ],
}
