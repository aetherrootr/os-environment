local k8sUtils = import "utils/k8s-utils.libsonnet";

{
    local chartPath = './charts/sm-operator',
    appName:: 'bitwarden-secrets-manager',
    namespace:: 'bitwarden-secrets-manager',


    bitwardenSecretsManager: k8sUtils.importFromHelmChart(
        projectPath=std.thisFile,
        name=$.appName,
        chart=chartPath,
        config={
            namespace: $.namespace,
        },
    ),
}
