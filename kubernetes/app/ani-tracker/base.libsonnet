local aniTracker = import 'ani-tracker.libsonnet';
local cronjob = import 'cronjob.libsonnet';
local postgres = import 'postgres.libsonnet';
local redis = import 'redis.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8080,
  databaseHost:: $.appName + '-postgres',
  databasePort:: 5432,
  databaseName:: $.appName,
  databaseUser:: $.appName,
  databasePasswordSecretName:: $.appName + '-postgres-secret',
  redisDatabaseHost:: $.appName + '-redis',
  redisDatabasePort:: 6379,
  appSecretName:: $.appName + '-secret',

  local aniTrackerResources = aniTracker {
    namespace: $.namespace,
    appName: $.appName,
    port: $.port,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
    appSecretName: $.appSecretName,
  },

  local postgresResources = postgres {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  local redisResources = redis {
    namespace: $.namespace,
    appName: $.appName,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
  },

  local cronjobResources = cronjob {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    aniTrackerResources.aniTracker +
    postgresResources.postgresdb +
    redisResources.redis +
    cronjobResources.cron
  ),
}
