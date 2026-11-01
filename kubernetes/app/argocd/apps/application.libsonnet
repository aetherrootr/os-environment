{
  namespace:: error 'namespace is required',
  project:: error 'project is required',
  appName:: error 'appName is required',
  appPath:: error 'appPath is required',
  destinationNamespace:: error 'destinationNamespace is required',
  environment:: 'env/prod.jsonnet',
  targetRevision:: 'master',
  automated:: true,

  assert std.startsWith($.appPath, 'kubernetes/app/') &&
         $.appPath != 'kubernetes/app/argocd' &&
         !std.startsWith($.appPath, 'kubernetes/app/argocd/') &&
         !std.member(std.split($.appPath, '/'), '..') :
    'Application sources must be workload projects outside the Argo CD directory',
  assert std.member($.project.destinationNamespaces, $.destinationNamespace) :
    'destinationNamespace must be allowed by the workload project',
  assert std.startsWith($.environment, 'env/') &&
         std.endsWith($.environment, '.jsonnet') &&
         !std.member(std.split($.environment, '/'), '..') :
    'environment must be a relative env/*.jsonnet entry',

  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: $.appName,
    namespace: $.namespace,
  },
  spec: {
    project: $.project.projectName,
    source: {
      repoURL: $.project.repoURL,
      targetRevision: $.targetRevision,
      path: $.appPath,
      plugin: {
        name: 'tanka-v1.0',
        env: [
          {
            name: 'TANKA_ENV',
            value: $.environment,
          },
        ],
      },
    },
    destination: {
      server: $.project.apiServer,
      namespace: $.destinationNamespace,
    },
    syncPolicy: {
      automated: {
        enabled: $.automated,
        prune: false,
        selfHeal: false,
        allowEmpty: false,
      },
      syncOptions: [
        'FailOnSharedResource=true',
      ],
      retry: {
        limit: 3,
        backoff: {
          duration: '10s',
          factor: 2,
          maxDuration: '2m',
        },
      },
    },
  },
}
