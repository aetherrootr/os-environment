local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  appName:: 'immich',
  namespace:: 'applications-and-services',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
