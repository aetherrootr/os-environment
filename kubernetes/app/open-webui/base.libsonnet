local openTerminal = import 'open-terminal.libsonnet';
local openWebui = import 'open-webui.libsonnet';
local networkPolicy = import 'network-policy.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8080,
  appSecretName:: $.appName + '-secret',
  openTerminalAppName:: 'open-terminal',
  openTerminalPort:: 8000,

  local openWebuiResources = openWebui {
    namespace: $.namespace,
    appName: $.appName,
    port: $.port,
    appSecretName: $.appSecretName,
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
    openWebuiResources.openWebui +
    openTerminalResources.openTerminal +
    networkPolicyResources.networkPolicy
  ),
}
