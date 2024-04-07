local base = import '../../base.libsonnet';
local env = import 'utils/inline-environments-base.libsonnet';

env{
namespace:: 'kubernetes-dashboard',
apiServer: "https://192.168.8.145:6443",

deployTarget: base{
    namespace: $.namespace
}
}
