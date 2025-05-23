local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace: 'applications-and-services',
  volumeName: 'data0-' + $.namespace,

  deployTarget: base {
    namespace: $.namespace,
    volumeName: $.volumeName,
  },
}
