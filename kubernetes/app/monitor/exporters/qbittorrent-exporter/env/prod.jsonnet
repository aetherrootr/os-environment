local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'qbittorrent-exporter',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
