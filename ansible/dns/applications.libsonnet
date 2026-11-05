local dnsUtils = import 'utils.libsonnet';

local k8sEdgeRouter = 'edge-router.corp.aetherrootr.com';

[
  // Applications using the edge-router ingress.
  dnsUtils.generateDNSAlias('kubernetes-dashboard.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('it-tools.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('subconverter.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('sub-cache.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('clipboard.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('wiki.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('go.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('files.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('library.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('ha.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('meet.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('bazarr.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('jackett.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('ani-tracker.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('finance.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('immich.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('jellyfin.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('jellyseerr.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('jproxy.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('open-webui.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('openlist.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('torrent.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('qbittorrent-api.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('radarr.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('searxng.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('sonarr.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('argocd.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('grafana.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('prometheus-clash.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('prometheus-common.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('prometheus-homeassistant.corp.aetherrootr.com', k8sEdgeRouter),
  dnsUtils.generateDNSAlias('prometheus.corp.aetherrootr.com', k8sEdgeRouter),
  // Use HAProxy's Gitea SSH address (.206:22), separate from management SSH (.205:22).
  dnsUtils.generateDNSRecord('gitea.corp.aetherrootr.com', '192.168.8.206'),

  // Resolve the public Authentik domain through the internal ingress on the LAN.
  dnsUtils.generateDNSAlias('authentik.aetherrootr.com', k8sEdgeRouter),

  // Short LAN name for the link service, allowing access via http://go/.
  dnsUtils.generateDNSAlias('go', k8sEdgeRouter),
  // Also resolve clients that append the LAN search domain to "go".
  // Use a fully qualified target to avoid a go -> go.lan -> go search-domain loop.
  dnsUtils.generateDNSAlias('go.lan', k8sEdgeRouter),
]
