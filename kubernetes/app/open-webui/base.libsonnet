local networkPolicy = import 'network-policy.libsonnet';
local openTerminal = import 'open-terminal.libsonnet';
local openWebui = import 'open-webui.libsonnet';
local postgres = import 'postgres.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8080,
  appSecretName:: $.appName + '-secret',
  databaseHost:: $.appName + '-postgres',
  databasePort:: 5432,
  databaseName:: 'open_webui',
  databaseUser:: 'open_webui',
  databasePasswordSecretName:: $.appName + '-postgres-secret',
  openTerminalAppName:: 'open-terminal',
  openTerminalPort:: 8000,

  local openWebuiResources = openWebui {
    namespace: $.namespace,
    appName: $.appName,
    port: $.port,
    appSecretName: $.appSecretName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
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

  local openTerminalResources = openTerminal {
    namespace: $.namespace,
    appSecretName: $.appSecretName,
    appName: $.openTerminalAppName,
    port: $.openTerminalPort,
  },

  local networkPolicyResources = networkPolicy {
    namespace: $.namespace,
    openWebuiAppName: $.appName,
    openTerminalAppName: $.openTerminalAppName,
    openTerminalPort: $.openTerminalPort,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    postgresResources.postgres +
    openWebuiResources.openWebui +
    openTerminalResources.openTerminal +
    networkPolicyResources.networkPolicy
  ),
}
