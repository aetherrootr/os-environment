local authentik = import 'authentik.libsonnet';
local postgresdb = import 'postgresdb.libsonnet';
local redis = import 'redis.libsonnet';
local authentikProxyOutpost = import 'outposts/proxy-outpost.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'authentik',
  authentikSecretName:: 'authentik-secret',
  redisDatabaseHost:: $.appName + '-redis',
  redisDatabasePort:: 6379,
  redisDatabasePasswordSecretName:: $.authentikSecretName,
  databaseHost:: $.appName + '-postgres',
  databasePort:: 5432,
  databaseName:: $.appName,
  databaseUser:: $.appName,
  databasePasswordSecretName:: $.authentikSecretName,

  local redisResources = redis {
    namespace: $.namespace,
    appName: $.redisDatabaseHost,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
    redisDatabasePasswordSecretName: $.redisDatabasePasswordSecretName,
  },

  local postgresResources = postgresdb {
    namespace: $.namespace,
    appName: $.databaseHost,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  local authentikResources = authentik {
    namespace: $.namespace,
    appName: $.appName,
    authentikSecretName: $.authentikSecretName,
    redisDatabaseHost: $.redisDatabaseHost,
    redisDatabasePort: $.redisDatabasePort,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
  },

  local authentikProxyOutpostResources = authentikProxyOutpost {
    namespace: $.namespace,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    redisResources.redis
    + postgresResources.postgresdb
    + authentikResources.authentik
    + authentikProxyOutpostResources.authentikProxyOutpost
  ),
}
