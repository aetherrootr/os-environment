local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'data-backup',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
    // Daily at 02:00 Asia/Shanghai (UTC+8).
    schedule: '0 2 * * *',
    retentionDays: 7,
    suspend: false,
  },
}
