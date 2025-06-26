local base = import '../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';

env {
  namespace:: 'infrastructure',

  deployTarget: base {
    namespace: $.namespace,
  },
}
