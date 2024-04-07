local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
    local chartPath = './charts/kubernetes-dashboard',
    appName:: 'kubernetes-dashboard',
    namespace:: 'kubernetes-dashboard',
    
    local helmConf = {
        namespace: $.namespace,
    },

    kubernetesDashboard: k8sUtils.importFromHelmChart(
        std.thisFile,
        $.appName,
        chartPath,
        helmConf),
}
