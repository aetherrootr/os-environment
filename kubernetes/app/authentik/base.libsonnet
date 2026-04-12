local authentik = import 'authentik.libsonnet';
local postgresdb = import 'postgresdb.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'authentik',
  authentikSecretName:: 'authentik-secret',
  databaseHost:: $.appName + '-postgres',
  databasePort:: 5432,
  databaseName:: $.appName,
  databaseUser:: $.appName,
  databasePasswordSecretName:: $.authentikSecretName,

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
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    postgresResources.postgresdb
    + authentikResources.authentik
  ),
}
