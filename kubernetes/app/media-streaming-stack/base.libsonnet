local bazarr = import 'bazarr.libsonnet';
local jeckett = import 'jackett.libsonnet';
local jellyfin = import 'jellyfin.libsonnet';
local jellyseerr = import 'jellyseerr.libsonnet';
local jproxy = import 'jproxy.libsonnet';
local qbittorrent = import 'qbittorrent.libsonnet';
local radarr = import 'radarr.libsonnet';
local sonarr = import 'sonarr.libsonnet';
local sqliteBackup = import 'utils/sqlite-backup.libsonnet';

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

  local sqliteBackupResources = sqliteBackup {
    namespace: $.namespace,
    appName: $.deployName,
    databasePaths: [
      'media_streaming_stack/bazarr_config/db/bazarr.db',
      'media_streaming_stack/jellyfin_config/data/jellyfin.db',
      'media_streaming_stack/jellyfin_config/data/library.db',
      'media_streaming_stack/jellyseerr_config/db/db.sqlite3',
      'media_streaming_stack/jproxy/jproxy.db',
      'media_streaming_stack/radarr_config/radarr.db',
      'media_streaming_stack/sonarr_config/sonarr.db',
    ],
    backupSubPath: 'media_streaming_stack/sqlite_backup',
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
    + sqliteBackupResources.cron
  ),
}
