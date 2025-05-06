local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
    namespace:: 'kubernetes-dashboard',
    appName::'kubernetes-dashboard',
    replicas:: 1,
    port:: 9090,
    
    local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],
    
    local containerImage = 'kubernetesui/dashboard:v2.7.0',

    local containers = k8sUtils.generateContainers(
        containerName=$.appName,
        image=containerImage,
        ports = [
            k8sUtils.generateContainerPort(name='http', containerPort=$.port),
        ],
        resources={
            requests: {
                cpu: '100m',
                memory: '128Mi',
            },
            limits: {
                cpu: '200m',
                memory: '256Mi',
            },
        },
        args=[
            '--enable-insecure-login',
            '--namespace=kubernetes-dashboard',
        ]
    ),

    apiVersion: 'apps/v1',
    kind: 'list',
    items: std.prune([
        k8sUtils.generateService(
            namespace=$.namespace,
            appName=$.appName,
            ports=[
                k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
            ],
        ),
        k8sUtils.generateDeployment(
            namespace=$.namespace,
            appName=$.appName,
            containers=containers,
            podSpec=k8sUtils.generatePodSpec(serviceAccountName=$.appName),
            replicas=$.replicas,
        ),
        k8sUtils.generateIngress(
            namespace=$.namespace,
            appName=$.appName,
            serviceName=$.appName,
            annotations={},
            port=$.port,
            hostnameList=hosts,
        )
    ]),
}
