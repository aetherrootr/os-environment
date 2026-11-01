local argoUtils = import 'utils/argo-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  projectName:: error 'projectName is required',
  repoURL:: error 'repoURL is required',
  apiServer:: 'https://kubernetes.default.svc',
  destinationNamespaces:: error 'destinationNamespaces is required',
  description:: '',
  clusterResourceWhitelist:: [],
  namespaceResourceWhitelist:: [],
  namespaceResourceBlacklist:: [
    { group: 'argoproj.io', kind: '*' },
    { group: 'rbac.authorization.k8s.io', kind: '*' },
    { group: '', kind: 'Secret' },
    { group: 'k8s.bitwarden.com', kind: '*' },
  ],
  notificationEmails:: [],
  notificationTriggers:: [
    'on-sync-running',
    'on-sync-succeeded',
    'on-deployed',
    'on-sync-failed',
    'on-health-degraded',
    'on-sync-status-unknown',
  ],

  assert !std.member($.destinationNamespaces, $.namespace) :
         'Workload projects must not target the Argo CD namespace',

  appProject: argoUtils.generateAppProject(
    namespace=$.namespace,
    projectName=$.projectName,
    sourceRepos=[$.repoURL],
    destinations=[
      {
        server: $.apiServer,
        namespace: namespace,
      }
      for namespace in $.destinationNamespaces
    ],
    clusterResourceWhitelist=$.clusterResourceWhitelist,
    namespaceResourceWhitelist=$.namespaceResourceWhitelist,
    namespaceResourceBlacklist=$.namespaceResourceBlacklist,
    description=$.description,
    annotations=if std.length($.notificationEmails) > 0 then {
      ['notifications.argoproj.io/subscribe.' + trigger + '.email']:
        std.join(';', $.notificationEmails)
      for trigger in $.notificationTriggers
    } else {},
  ),
}
