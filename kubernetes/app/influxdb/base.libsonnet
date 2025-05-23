local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8181,
  replicas:: 1,

  local containerImage = 'influxdb:3-core',
  local dataDir = '/var/lib/influxdb3',

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1Gi',
      },
    },
    command=[
      'influxdb3',
      'serve',
      '--node-id=node0',
      '--object-store=file',
      '--data-dir=' + dataDir,
    ],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-pvc',
        mountPath=dataDir,
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
  ),

  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
      ],
    ),
    k8sUtils.generateStatefulSet(
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
  ]),
}
