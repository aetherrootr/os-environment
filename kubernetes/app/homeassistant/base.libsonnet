local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'homeassistant',
  replicas:: 1,
  port:: 8123,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  urlPrefix:: 'ha',

  local containerImage = 'ghcr.io/home-assistant/home-assistant:stable',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.urlPrefix)],

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    privileged=true,
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '512Mi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/config',
        subPath=$.appName,
      ),
      k8sUtils.generateVolumeMount(
        name='localtime',
        mountPath='/etc/localtime',
        readOnly=true,
      ),
      k8sUtils.generateVolumeMount(
        name='dbus',
        mountPath='/run/dbus',
        readOnly=true,
      ),
    ],
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
            name: $.appName + '-config-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
          k8sUtils.generateHostPathVolume(
            name='localtime',
            path='/etc/localtime',
            type='File',
          ),
          k8sUtils.generateHostPathVolume(
            name='dbus',
            path='/run/dbus',
            type='Directory',
          ),
        ],
        nodeSelector={
          bluetooth: 'exist',
          'kubernetes.io/hostname': 'k8s-node-1',
        },
        hostNetwork=true,
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
