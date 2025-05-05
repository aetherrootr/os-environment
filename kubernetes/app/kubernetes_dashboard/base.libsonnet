local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
    namespace:: 'kubernetes-dashboard',
    appName::'kubernetes-dashboard',
    replicas:: 1,
    port:: 8443,
    
    local containerImage = 'kubernetesui/dashboard:v2.7.0',

    local containers = k8sUtils.generateContainers(
        containerName=$.appName,
        image=containerImage,
        ports = [
            k8sUtils.generateContainerPort(name='http', containerPort=9090),
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
            '--namespace=kubernetes-dashboard',
            '--enable-skip-login',
            '--enable-insecure-login',
            '--disable-settings-authorizer',
        ]
    ),

    apiVersion: 'apps/v1',
    kind: 'list',
    items: std.prune([
        k8sUtils.generateService(
            namespace=$.namespace,
            appName=$.appName,
            ports=[
                k8sUtils.generateServicePort(name='http', port=$.port, targetPort=9090, nodePort=30000),
            ],
            type='NodePort',
        ),
        k8sUtils.generateDeployment(
            namespace=$.namespace,
            appName=$.appName,
            containers=containers,
            podSpec=k8sUtils.generatePodSpec(),
            replicas=$.replicas,
        ),
    ]),
}
