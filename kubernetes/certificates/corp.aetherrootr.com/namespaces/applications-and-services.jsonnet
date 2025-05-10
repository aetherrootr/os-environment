local base = import '../base.libsonnet';
local env = import 'utils/inline-environments-base.libsonnet';

env{
    namespace:: 'applications-and-services',

    deployTarget: base{
        namespace: $.namespace,
    }
}
