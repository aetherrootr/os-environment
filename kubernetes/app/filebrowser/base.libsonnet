local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 8080,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'gtstef/filebrowser:latest',
  local hosts = [k8sUtils.getServiceHostname(serviceName='files')],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '128Mi',
      },
      limits: {
        cpu: '500m',
        memory: '1Gi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-database-pvc',
        mountPath='/home/filebrowser/database',
        subPath=$.appName,
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
      ),
      k8sUtils.generateVolumeMount(
        name='config',
        mountPath='/home/filebrowser/config.yaml',
        subPath='config.yaml',
        readOnly=true,
      ),
    ],
    env=[
      k8sUtils.generateEnv('TZ', 'Asia/Shanghai'),
    ]
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'config.yaml': importstr 'config/config.yaml',
      },
    ),
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
          k8sUtils.generateConfigMapVolume(
            name='config',
            configMapName=$.appName,
            items=[
              k8sUtils.generateVolumeItem(
                key='config.yaml',
                path='config.yaml',
              ),
            ],
          ),
          {
            name: $.appName + '-data-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='data0',
              ),
            },
          },
          {
            name: $.appName + '-database-pvc',
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
