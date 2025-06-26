local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';
local k8sUtil = import 'utils/k8s-utils.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: 'authentik-ldap-outpost',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
  },
}
