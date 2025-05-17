local postgresdb = import 'postgresdb.libsonnet';
local gitea = import 'gitea.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  databaseHost:: $.appName + '-postgresdb',
  databasePort:: 5432,
  databaseName:: 'gitea',
  databaseUser:: 'gitea',
  databasePasswordSecretName:: 'gitea-postgresdb-secret',

  local giteaResources = gitea {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  local postgresdbResources = postgresdb {
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
    giteaResources.gitea + postgresdbResources.postgresdb,
  ),
}
