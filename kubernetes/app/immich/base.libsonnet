local immichMachineLearning = import 'immich_machine_learning.libsonnet';
local immichServer = import 'immich_server.libsonnet';
local postgresdb = import 'postgresdb.libsonnet';
local redis = import 'redis.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  immichVersion:: 'v2.0.1',
  postgresDatabaseHost:: $.appName + '-postgresdb',
  postgresDatabasePort:: 5432,
  postgresDatabaseName:: $.appName,
  postgresDatabaseUser:: $.appName,
  postgresDatabasePasswordSecretName:: 'immich-postgresdb-secret',
  redisDatabaseHost:: $.appName + '-redis',
  redisDatabasePort:: 6379,
  immichServerPort: 2283,
  immichMlPort: 3003,

  local redisResources = redis {
    namespace: $.namespace,
    appName: $.redisDatabaseHost,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
  },
  local postgresResources = postgresdb {
    namespace: $.namespace,
    appName: $.postgresDatabaseHost,
    databaseHost: $.postgresDatabaseHost,
    databasePort: $.postgresDatabasePort,
    databaseName: $.postgresDatabaseName,
    databaseUser: $.postgresDatabaseUser,
    databasePasswordSecretName: $.postgresDatabasePasswordSecretName,
  },
  local  immichMachineLearningResources = immichMachineLearning {
    namespace: $.namespace,
    appName: $.appName,
    immichVersion: $.immichVersion,
    immichMlPort: $.immichMlPort,
  },
  local immichServerResources = immichServer {
    namespace: $.namespace,
    appName: $.appName,
    immichVersion: $.immichVersion,
    postgresDatabaseHost: $.postgresDatabaseHost,
    postgresDatabasePort: $.postgresDatabasePort,
    postgresDatabaseName: $.postgresDatabaseName,
    postgresDatabaseUser: $.postgresDatabaseUser,
    postgresDatabasePasswordSecretName: $.postgresDatabasePasswordSecretName,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
    immichServerPort: $.immichServerPort,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    redisResources.redis +
    postgresResources.postgresdb +
    immichMachineLearningResources.immich_ml +
    immichServerResources.immich_server
  ),
}
