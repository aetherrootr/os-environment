local postgresdb = import "postgresdb.libsonnet";
local wikijs = import "wikijs.libsonnet";

{
  namespace:: error ("namespace is required"),
  appName:: error ("appName is required"),
  databaseHost:: $.appName + "-postgresdb",
  databasePort:: 5432,
  databaseName:: "wiki",
  databaseUser:: "wikijs",
  databasePasswordSecretName:: "wikijs-postgresdb-secret",

  local wikijsResources = wikijs {
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


  apiVersion: "apps/v1",
  kind: "list",
  items: std.prune(
    wikijsResources.wikijs + postgresdbResources.postgresdb,
  ),
}
