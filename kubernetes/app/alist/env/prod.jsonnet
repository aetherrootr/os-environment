local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'applications-and-services',
  appName:: 'alist',

  deployTarget: base {
    namespace: $.namespace,
    appName: $.appName,
  },
}
