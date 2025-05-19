local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 9501,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'ghcr.io/jonnyan404/cloud-clipboard-go:latest',
  local hosts = [k8sUtils.getServiceHostname(serviceName='clipboard')],

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
        memory: '512Mi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name='config',
        mountPath='/app/server-node/config.json',
        subPath='config.json',
        readOnly=true,
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-pvc',
        mountPath='/storage',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'config.json': std.manifestJson(
          {
            server: {
              host: [],
              port: $.port,
              prefix: '',
              history: 20,
              auth: false,
              historyFile: '/storage/history.json',
              storageDir: '/storage',
            },
            text: {
              limit: 10240,
            },
            file: {
              expire: 3600,
              chunk: 5242880,
              limit: 1073741825,
            },
          }
        ),
      }
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
              k8sUtils.generateConfigMapVolumeItem(
                key='config.json',
                path='config.json',
              ),
            ],
          ),
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
