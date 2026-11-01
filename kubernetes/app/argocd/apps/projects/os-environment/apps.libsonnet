[
  {
    appName: 'ani-tracker-prod',
    appPath: 'kubernetes/app/ani-tracker',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'authentik-prod',
    appPath: 'kubernetes/app/authentik',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'authentik-ldap-outpost-prod',
    appPath: 'kubernetes/app/authentik/outposts/ldap-outpost',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'authentik-proxy-outpost-bazarr-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/bazarr/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-cloud-clipboard-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/cloud-clipboard/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-it-tools-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/it-tools/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-jackett-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/jackett/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-jproxy-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/jproxy/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-prometheus-clash-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-clash/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-prometheus-common-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-common/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-prometheus-homeassistant-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-homeassistant/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-qbittorrent-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/qbittorrent/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-radarr-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/radarr/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-sonarr-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'applications-and-services',
    environment: 'env/sonarr/prod.jsonnet',
  },
  {
    appName: 'authentik-proxy-outpost-thanos-querier-prod',
    appPath: 'kubernetes/app/authentik/outposts/proxy-outpost',
    destinationNamespace: 'infrastructure',
    environment: 'env/thanos-querier/prod.jsonnet',
  },
  {
    appName: 'bitwarden-secrets-manager-prod',
    appPath: 'kubernetes/app/bitwarden-secrets-manager',
    destinationNamespace: 'bitwarden-secrets-manager',
  },
  {
    appName: 'cert-manager-letsencrypt-prod',
    appPath: 'kubernetes/app/cert-manager/letsencrypt',
    destinationNamespace: 'cert-manager',
  },
  {
    appName: 'cloud-clipboard-prod',
    appPath: 'kubernetes/app/cloud-clipboard',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'cloudflared-prod',
    appPath: 'kubernetes/app/cloudflared',
    destinationNamespace: 'cloudflare-tunnel',
  },
  {
    appName: 'data-backup-prod',
    appPath: 'kubernetes/app/data-backup',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'filebrowser-prod',
    appPath: 'kubernetes/app/filebrowser',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'firefly-iii-prod',
    appPath: 'kubernetes/app/firefly-iii',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'gitea-prod',
    appPath: 'kubernetes/app/gitea',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'golinks-prod',
    appPath: 'kubernetes/app/golinks',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'grafana-prod',
    appPath: 'kubernetes/app/grafana',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'homeassistant-prod',
    appPath: 'kubernetes/app/homeassistant',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'immich-prod',
    appPath: 'kubernetes/app/immich',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'it-tools-prod',
    appPath: 'kubernetes/app/it-tools',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'jitsi-prod',
    appPath: 'kubernetes/app/jitsi',
    destinationNamespace: 'applications-and-services',
    // The chart generates random credentials; retain existing Secret data.
    syncOptions: [
      'FailOnSharedResource=true',
      'RespectIgnoreDifferences=true',
    ],
    ignoreDifferences: [
      {
        group: '',
        kind: 'Secret',
        jsonPointers: ['/data'],
      },
      {
        group: 'apps',
        kind: 'Deployment',
        name: 'jitsi-jitsi-meet-jicofo',
        jsonPointers: ['/spec/template/metadata/annotations/checksum~1secret'],
      },
      {
        group: 'apps',
        kind: 'Deployment',
        name: 'jitsi-jitsi-meet-jvb',
        jsonPointers: ['/spec/template/metadata/annotations/checksum~1secret'],
      },
    ],
  },
  {
    appName: 'komga-prod',
    appPath: 'kubernetes/app/komga',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'kubernetes-dashboard-prod',
    appPath: 'kubernetes/app/kubernetes-dashboard',
    destinationNamespace: 'kubernetes-dashboard',
  },
  {
    appName: 'media-streaming-stack-prod',
    appPath: 'kubernetes/app/media-streaming-stack',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'clash-exporter-prod',
    appPath: 'kubernetes/app/monitor/exporters/clash-exporter',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'kube-state-metrics-prod',
    appPath: 'kubernetes/app/monitor/exporters/kube-state-metrics',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'qbittorrent-exporter-prod',
    appPath: 'kubernetes/app/monitor/exporters/qbittorrent-exporter',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'ups-exporter-prod',
    appPath: 'kubernetes/app/monitor/exporters/ups-exporter',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'prometheus-clash-prod',
    appPath: 'kubernetes/app/monitor/prometheus',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-clash/prod.jsonnet',
  },
  {
    appName: 'prometheus-common-prod',
    appPath: 'kubernetes/app/monitor/prometheus',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-common/prod.jsonnet',
  },
  {
    appName: 'prometheus-homeassistant-prod',
    appPath: 'kubernetes/app/monitor/prometheus',
    destinationNamespace: 'infrastructure',
    environment: 'env/prometheus-homeassistant/prod.jsonnet',
  },
  {
    appName: 'thanos-querier-prod',
    appPath: 'kubernetes/app/monitor/thanos-querier',
    destinationNamespace: 'infrastructure',
  },
  {
    appName: 'open-webui-prod',
    appPath: 'kubernetes/app/open-webui',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'openlist-prod',
    appPath: 'kubernetes/app/openlist',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'searxng-prod',
    appPath: 'kubernetes/app/searxng',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'sub-cache-prod',
    appPath: 'kubernetes/app/sub-cache',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'subconverter-prod',
    appPath: 'kubernetes/app/subconverter',
    destinationNamespace: 'applications-and-services',
  },
  {
    appName: 'wikijs-prod',
    appPath: 'kubernetes/app/wikijs',
    destinationNamespace: 'applications-and-services',
  },
]
