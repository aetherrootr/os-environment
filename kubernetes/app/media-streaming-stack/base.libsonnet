local bazarr = import 'bazarr.libsonnet';
local jeckett = import 'jackett.libsonnet';
local jellyfin = import 'jellyfin.libsonnet';
local jellyseerr = import 'jellyseerr.libsonnet';
local jproxy = import 'jproxy.libsonnet';
local qbittorrent = import 'qbittorrent.libsonnet';
local radarr = import 'radarr.libsonnet';
local sonarr = import 'sonarr.libsonnet';

{
  namespace:: error ('namespace is required'),
  deployName: 'media-streaming-stack',

  local bazarrResources = bazarr {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local jeckettResources = jeckett {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local jellyfinResources = jellyfin {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local jellseerrResources = jellyseerr {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local jproxyResources = jproxy {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local qbittorrentResources = qbittorrent {
    namespace: $.namespace,
    deployName: $.deployName,
  },
  
  local radarrResources = radarr {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  local sonarrResources = sonarr {
    namespace: $.namespace,
    deployName: $.deployName,
  },

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune(
    bazarrResources.bazarr
    + jeckettResources.jackett
    + jellyfinResources.jellyfin
    + jellseerrResources.jellyseerr
    + jproxyResources.jproxy
    + qbittorrentResources.qbittorrent
    + radarrResources.radarr
    + sonarrResources.sonarr
  ),
}
