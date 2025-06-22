local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';
local k8sUtil = import 'utils/k8s-utils.libsonnet';

env {
  namespace:: 'infrastructure',
  appName:: k8sUtil.getAuthProxyOutpostAppName('prometheus-common'),
  authentikTokenSecretName:: 'prometheus-common-secret',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
    authentikTokenSecretName: $.authentikTokenSecretName,
  },
}
