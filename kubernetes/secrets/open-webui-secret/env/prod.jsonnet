local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'applications-and-services',

  deployTarget: base {
    namespace: $.namespace,
  },
}
