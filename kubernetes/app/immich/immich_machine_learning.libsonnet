local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  immichVersion:: error ('immichVersion is required'),
  immichMlPort:: error ('immichMlPort is required'),
  replicas:: 1,

  local containerImage = "ghcr.io/immich-app/immich-machine-learning:"+ $.immichVersion + "-openvino",
  local appEnv = std.prune([
    k8sUtils.generateEnv(name='IMMICH_PORT', value=std.toString($.immichMlPort)),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName + "-ml",
    image=containerImage,
    privileged=true,
    ports=[
      k8sUtils.generateContainerPort(name='model', containerPort=$.immichMlPort),
    ],
    resources={
      requests: {
        memory: '256Mi',
      },
      limits: {
        memory: '1Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-cache-pvc',
        mountPath='/cache',
        subPath=std.strReplace($.appName + '/model-cache', '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name='dev-dri',
        mountPath='/dev/dri',
      ),
      k8sUtils.generateVolumeMount(
        name='dev-usb',
        mountPath='/dev/bus/usb',
      ),
    ],
  ),

  immich_ml: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName + "-ml",
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.immichMlPort, targetPort=$.immichMlPort),
      ],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName + "-ml",
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: $.appName + '-cache-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
          k8sUtils.generateHostPathVolume(
            name='dev-dri',
            path='/dev/dri',
            type='Directory',
          ),
          k8sUtils.generateHostPathVolume(
            name='dev-usb',
            path='/dev/bus/usb',
            type='Directory',
          ),
        ],
        nodeSelector={
          gpu: 'intel',
        },
      ),
      replicas=$.replicas,
    ),
  ])
}
