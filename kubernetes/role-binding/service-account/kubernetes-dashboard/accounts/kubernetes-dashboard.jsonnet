local env = import 'utils/inline-environments-base.libsonnet';
local base = import '../base.libsonnet';

env{
    namespace:: 'kubernetes-dashboard',
    appName:: 'kubernetes-dashboard',

    deployTarget: base{
        namespace: $.namespace,
        appName: $.appName,
    },
}
