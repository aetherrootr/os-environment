local k8sUtils = import 'utils/k8s-utils.libsonnet';
local core = import 'core.libsonnet';
local progresdb = import 'progresdb.libsonnet';
local cronjob = import 'cronjob.libsonnet';

{
  namespace:: error('namespace is required'),
  appName:: error ('appName is required'),
  databaseHost:: $.appName + '-db',
  databasePort:: 5432,
  databaseName:: $.appName,
  databaseUser:: $.appName,
  appSecretName:: 'firefly-iii-secret',

  local coreResources = core {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    appSecretName: $.appSecretName,
  },

  local progresdbResources = progresdb {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databaseSecretName: $.appSecretName,
  },

  local cronjobResources = cronjob {
    namespace: $.namespace,
    appName: $.appName,
    appSecretName: $.appSecretName,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    coreResources.core
    + progresdbResources.postgresdb
    + cronjobResources.cron
  ),
}
