local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 3000,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'grafana/grafana:latest',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '250m',
        memory: '750Mi',
      },
      limits:{}
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-pvc',
        mountPath='/var/lib/grafana',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
    env=[
        k8sUtils.generateEnv(name='GF_SECURITY_ADMIN_USER', value='admin'),
        k8sUtils.generateSecretEnv(name='GF_SECURITY_ADMIN_PASSWORD', secretName='grafana-secret', key='password'),
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
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: $.appName + '-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
        ],
      ),
      replicas=$.replicas,
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName,
      serviceName=$.appName,
      annotations={},
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
