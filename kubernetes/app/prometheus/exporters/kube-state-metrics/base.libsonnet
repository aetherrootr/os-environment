local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  local chartPath = './charts/kube-state-metrics',
  appName:: 'kube-monitor',
  namespace:: 'infrastructure',


  bitwardenSecretsManager: k8sUtils.importFromHelmChart(
    projectPath=std.thisFile,
    name=$.appName,
    chart=chartPath,
    config={
      namespace: $.namespace,
    },
  ),
}
