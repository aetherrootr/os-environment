local kubernetesDashboardNamespace = import 'kubernetes-dashboard/base.libsonnet';
local applicationsAndServicesNamespace = import 'applications-and-services/base.libsonnet';

{
    apiVersion: 'v1',
    kind: 'list',
    items: std.prune([
        kubernetesDashboardNamespace.namespace,
        applicationsAndServicesNamespace.namespace,
    ]),
}
