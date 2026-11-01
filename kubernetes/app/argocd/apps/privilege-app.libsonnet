local argoUtils = import 'utils/argo-utils.libsonnet';

// A Privilege App can manage Application and AppProject resources in argocd.
// Do not add one unless necessary; additions require review of its source and permissions.
{
  project:: error 'project is required',
  namespace:: $.project.namespace,
  appName:: error 'appName is required',
  projectName:: error 'projectName is required',
  appPath:: error 'appPath is required',
  environment:: error 'environment is required',

  apiVersion: 'v1',
  kind: 'List',
  items: [
    // Restrict the parent to registration resources in the Argo CD namespace.
    argoUtils.generateAppProject(
      namespace=$.namespace,
      projectName=$.projectName,
      sourceRepos=[$.project.repoURL],
      destinations=[
        { server: $.project.apiServer, namespace: $.namespace },
      ],
      clusterResourceWhitelist=[],
      namespaceResourceWhitelist=[
        { group: 'argoproj.io', kind: 'AppProject' },
        { group: 'argoproj.io', kind: 'Application' },
      ],
      description='Application registrations; the Argo CD installation is managed independently',
    ),
    argoUtils.generateApplication(
      namespace=$.namespace,
      appName=$.appName,
      projectName=$.projectName,
      source={
        repoURL: $.project.repoURL,
        targetRevision: 'master',
        // Reuse the existing dependency project and its pinned lock file.
        path: $.appPath,
        plugin: {
          name: 'tanka-v1.0',
          env: [
            { name: 'TANKA_ENV', value: $.environment },
          ],
        },
      },
      destination={
        server: $.project.apiServer,
        namespace: $.namespace,
      },
      syncPolicy={
        automated: {
          enabled: true,
          prune: false,
          selfHeal: false,
          allowEmpty: false,
        },
        syncOptions: ['FailOnSharedResource=true'],
        retry: {
          limit: 3,
          backoff: { duration: '10s', factor: 2, maxDuration: '2m' },
        },
      },
    ),
  ],
}
