local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'applications-and-services',
  appName:: 'sgcc-electricity',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
