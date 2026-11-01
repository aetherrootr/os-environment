local application = import 'application.libsonnet';
local privilegeAppTemplate = import 'privilege-app.libsonnet';
local projectTemplate = import 'project.libsonnet';

local projects = [
  {
    config: import 'projects/os-environment/project.libsonnet',
    deployments: (import 'projects/os-environment/apps.libsonnet') +
                 (import 'projects/os-environment/secrets.libsonnet'),
    // Privilege Apps can manage Applications and AppProjects in argocd.
    // Do not add one unless necessary. Reviewers must check its source,
    // destination and resource permissions before approving additions.
    privilegeApps: [
      {
        appName: 'os-environment-apps-prod',
        projectName: 'os-environment-apps',
        appPath: 'kubernetes/app/argocd',
        environment: 'apps/env/prod.jsonnet',
      },
    ],
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
    [project.appProject] + [
      ((application + deployment) {
         namespace: $.namespace,
         project: project,
       }).application
      for deployment in entry.deployments
    ] + std.flattenArrays([
      ((privilegeAppTemplate + config) { project: project }).items
      for config in entry.privilegeApps
    ])
    for entry in projects
  ]),
}
