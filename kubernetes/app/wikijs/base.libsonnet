local postgresdb = import 'postgresdb.libsonnet';
local postgresBackup = import 'utils/postgres-backup.libsonnet';
local wikijs = import 'wikijs.libsonnet';
local wikijsV3 = import 'v3.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  // Keep v2 online while the independent v3 database is populated and verified.
  activeVersion:: 'v2',
  v3Replicas:: if $.activeVersion == 'v3' then 1 else 0,
  databaseHost:: $.appName + '-postgresdb',
  databasePort:: 5432,
  databaseName:: 'wiki',
  databaseUser:: 'wikijs',
  databasePasswordSecretName:: 'wikijs-postgresdb-secret',

  local wikijsResources = wikijs {
    namespace: $.namespace,
    appName: $.appName,
    replicas: if $.activeVersion == 'v3' then 0 else 1,
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

  local postgresBackupResources = postgresBackup {
    namespace: $.namespace,
    appName: $.appName,
    databaseHost: $.databaseHost,
    databasePort: $.databasePort,
    databaseName: $.databaseName,
    databaseUser: $.databaseUser,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  local v3Resources = wikijsV3 {
    namespace: $.namespace,
    appReplicas: $.v3Replicas,
    databasePasswordSecretName: $.databasePasswordSecretName,
  },

  // Wiki.js 3 normalizes this existing page's path; keep old bookmarks working.
  local legacyPathRedirect = {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: $.appName + '-v2-path-redirect',
      namespace: $.namespace,
      annotations: if $.activeVersion == 'v3' then {
        'nginx.ingress.kubernetes.io/permanent-redirect':
          'https://wiki.corp.aetherrootr.com/finance/money-market-funds',
        'nginx.ingress.kubernetes.io/permanent-redirect-code': '308',
      } else {},
    },
    spec: {
      ingressClassName: 'nginx',
      rules: [{
        host: 'wiki.corp.aetherrootr.com',
        http: { paths: [{
          path: '/finance/Money_market_funds',
          pathType: 'Exact',
          backend: { service: {
            name: if $.activeVersion == 'v3' then 'wikijs-v3' else $.appName,
            port: { number: 3000 },
          } },
        }] },
      }],
      tls: [{
        hosts: ['wiki.corp.aetherrootr.com'],
        secretName: $.namespace + '-wildcard-certificate-tls',
      }],
    },
  },

  assert std.member(['v2', 'v3'], $.activeVersion) : 'activeVersion must be v2 or v3',


  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    [
      if resource.kind == 'Ingress' && $.activeVersion == 'v3' then
        resource {
          spec+: {
            rules: [
              rule {
                http+: {
                  paths: [
                    path { backend+: { service+: { name: 'wikijs-v3' } } }
                    for path in rule.http.paths
                  ],
                },
              }
              for rule in resource.spec.rules
            ],
          },
        }
      else resource
      for resource in wikijsResources.wikijs
    ] + postgresdbResources.postgresdb + postgresBackupResources.cron + v3Resources.items +
    [legacyPathRedirect],
  ),
}
