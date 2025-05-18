local base = import 'utils/node-config-base.libsonnet';
local env = import 'common/inline-environments-base.libsonnet';
local nodeGroupList = import 'node-groups.libsonnet';

env {
    namespace: 'default',

    deployTarget: base {
        nodeGroupList: nodeGroupList,
    },
}
