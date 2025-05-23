local k8sUtils = import 'utils/k8s-utils.libsonnet';
local prometheusYml = importstr 'config/prometheus.yml';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 9090,
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containerImage = 'prom/prometheus:latest',

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
    args=[
      '--config.file=/etc/prometheus/prometheus.yml',
      '--storage.tsdb.path=/prometheus',
      '--web.console.libraries=/usr/share/prometheus/console_libraries',
      '--web.console.templates=/usr/share/prometheus/consoles',
    ],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data',
        mountPath='/prometheus',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config',
        mountPath='/etc/prometheus',
        readOnly=true,
      ),
    ],
  ),
  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'prometheus.yml': prometheusYml,
      },
    ),
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
          k8sUtils.generateHostPathVolume(
            name=$.appName + '-data',
            path='/media/service_data/prometheus',
            type='DirectoryOrCreate',
          ),
          k8sUtils.generateConfigMapVolume(
            name=$.appName + '-config',
            configMapName=$.appName,
          ),
        ],
        nodeSelector={
          'service-data-mount': 'true',
        }
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
