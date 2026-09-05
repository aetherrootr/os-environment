local cronjob = import 'cronjob.libsonnet';
local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'data-backup',
  schedule:: '0 2 * * *',
  suspend:: true,
  retentionDays:: 7,

  apiVersion: 'v1',
  kind: 'List',
  items: [
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'backup.sh': importstr 'scripts/backup.sh',
        'paths.txt': importstr 'paths.txt',
      },
    ),
    (cronjob { config:: $ }).cron,
  ],
}
