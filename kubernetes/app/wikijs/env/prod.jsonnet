local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'applications-and-services',
  appName:: 'wikijs',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
