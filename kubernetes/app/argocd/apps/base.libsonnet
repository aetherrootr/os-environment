local projectTemplate = import 'project.libsonnet';
local application = import 'application.libsonnet';

local projects = [
  {
    config: import 'projects/os-environment/project.libsonnet',
    apps: import 'projects/os-environment/apps.libsonnet',
  },
];

{
  namespace:: error 'namespace is required',

  apiVersion: 'v1',
  kind: 'List',
  items: std.flattenArrays([
    local project = (projectTemplate + entry.config) {
      namespace: $.namespace,
    };
    [project] + [
      (application + app) {
        namespace: $.namespace,
        project: project,
      }
      for app in entry.apps
    ]
    for entry in projects
  ]),
}
