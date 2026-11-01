local argoUtils = import 'utils/argo-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  project:: error 'project is required',
  appName:: error 'appName is required',
  appPath:: error 'appPath is required',
  destinationNamespace:: error 'destinationNamespace is required',
  environment:: 'env/prod.jsonnet',
  targetRevision:: 'master',
  automated:: true,
  syncOptions:: [
    'FailOnSharedResource=true',
  ],
  ignoreDifferences:: [],

  assert (std.startsWith($.appPath, 'kubernetes/app/') ||
          std.startsWith($.appPath, 'kubernetes/secrets/')) &&
         $.appPath != 'kubernetes/app/argocd' &&
         !std.startsWith($.appPath, 'kubernetes/app/argocd/') &&
         !std.member(std.split($.appPath, '/'), '..') :
         'Application sources must be workload or secret projects outside the Argo CD directory',
  assert std.member($.project.destinationNamespaces, $.destinationNamespace) :
         'destinationNamespace must be allowed by the workload project',
  assert std.startsWith($.environment, 'env/') &&
         std.endsWith($.environment, '.jsonnet') &&
         !std.member(std.split($.environment, '/'), '..') :
         'environment must be a relative env/*.jsonnet entry',

  application: argoUtils.generateApplication(
    namespace=$.namespace,
    appName=$.appName,
    projectName=$.project.projectName,
    source={
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
    destination={
      server: $.project.apiServer,
      namespace: $.destinationNamespace,
    },
    syncPolicy={
      automated: {
        enabled: $.automated,
        prune: false,
        selfHeal: false,
        allowEmpty: false,
      },
      syncOptions: $.syncOptions,
      retry: {
        limit: 3,
        backoff: {
          duration: '10s',
          factor: 2,
          maxDuration: '2m',
        },
      },
    },
    ignoreDifferences=$.ignoreDifferences,
  ),
}
