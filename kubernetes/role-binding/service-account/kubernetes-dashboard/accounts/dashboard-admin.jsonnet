local env = import 'utils/inline-environments-base.libsonnet';
local base = import '../base.libsonnet';

env{
    namespace:: 'kubernetes-dashboard',
    appName:: 'dashboard-admin',

    deployTarget: base{
        namespace: $.namespace,
        appName: $.appName,
    },
}
