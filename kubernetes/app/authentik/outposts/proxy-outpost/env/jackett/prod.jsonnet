local base = import '../../base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';
local k8sUtil = import 'utils/k8s-utils.libsonnet';

env {
  namespace:: 'applications-and-services',
  appName:: k8sUtil.getAuthProxyOutpostAppName('jackett'),
  authentikTokenSecretName:: 'jackett-secret',

  deployTarget: base {
    appName: $.appName,
    namespace: $.namespace,
    authentikTokenSecretName: $.authentikTokenSecretName,
  },
}
