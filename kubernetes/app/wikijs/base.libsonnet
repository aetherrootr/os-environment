local postgresdbUtils = import "postgresdb.libsonnet";
local wikijsUtils = import "wikijs.libsonnet";

{
  namespace:: error ("namespace is required"),
  appName:: error ("appName is required"),
  databaseHost:: $.appName + "-postgresdb",
  databasePort:: 5432,
  databaseName:: "wiki",
  databaseUser:: "wikijs",
  databasePasswordSecretName:: "wikijs-postgresdb-secret",

  local wikijs = wikijsUtils {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  local postgresdb = postgresdbUtils {
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
    wikijs.wikijs + postgresdb.postgresdb,
  ),
}
