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
    // Weekly snapshot waits for Sunday's latest generation before it starts.
    snapshotSchedule: '0 3 * * 0',
    snapshotDeadlineSeconds: 79200,
    snapshotRetentionDays: 56,
    suspend: false,
  },
}
