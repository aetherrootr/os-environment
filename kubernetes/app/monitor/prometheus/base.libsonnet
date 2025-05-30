local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  retentionTime:: error ('retentionTime is required'),
  prometheusYml:: error ('prometheusYml is required'),
  port:: 9090,
  thanosSidecarGrpcPort:: 10901,
  thanosSidecarHttpPort:: 10902,
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  rulesConfig:: null,
  withHomeAssistantToken:: false,
  disableThanosSidecar:: false,

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containerImage = 'prom/prometheus:latest',
  local sidecarImage = 'thanosio/thanos:v0.38.0',

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
      '--storage.tsdb.retention.time=' + $.retentionTime,
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
    ] + (
      if $.rulesConfig != null then [
        k8sUtils.generateVolumeMount(
          name=$.appName + '-rule',
          mountPath='/etc/prometheus/rules',
          readOnly=true,
        ),
      ] else []
    ) + (
      if $.withHomeAssistantToken then [
        k8sUtils.generateVolumeMount(
          name='homeassistant-token',
          mountPath='/etc/secrets/homeassistant_token',
          readOnly=true,
          subPath='homeassistant_token',
        ),
      ] else []
    ),
  ),

  local sidecarContainers = k8sUtils.generateContainers(
    containerName='thanos-sidecar',
    image=sidecarImage,
    args=[
      'sidecar',
      '--tsdb.path=/prometheus',
      '--prometheus.url=http://localhost:' + std.toString($.port),
      '--grpc-address=0.0.0.0:' + std.toString($.thanosSidecarGrpcPort),
      '--http-address=0.0.0.0:' + std.toString($.thanosSidecarHttpPort),
    ],
    ports=[
      k8sUtils.generateContainerPort(name='grpc', containerPort=$.thanosSidecarGrpcPort),
      k8sUtils.generateContainerPort(name='http', containerPort=$.thanosSidecarHttpPort),
    ],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data',
        mountPath='/prometheus',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
    resources={
      requests: {
        cpu: '50m',
        memory: '128Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1Gi',
      },
    },
  ),

  apiVersion: 'apps/v1',
  kind: 'List',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        'prometheus.yml': $.prometheusYml,
      } + (if $.rulesConfig != null then $.rulesConfig else {}),
    ),
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
        k8sUtils.generateServicePort(name='grpc-sidecar', port=$.thanosSidecarGrpcPort, targetPort=$.thanosSidecarGrpcPort),
        k8sUtils.generateServicePort(name='http-sidecar', port=$.thanosSidecarHttpPort, targetPort=$.thanosSidecarHttpPort),
      ],
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.appName,
      containers=[containers] + (if $.disableThanosSidecar then [] else [sidecarContainers]),
      podSpec=k8sUtils.generatePodSpec(
        serviceAccountName='prometheus',
        volumes=[
                  k8sUtils.generateHostPathVolume(
                    name=$.appName + '-data',
                    path='/media/service_data/prometheus',
                    type='DirectoryOrCreate',
                  ),
                  k8sUtils.generateConfigMapVolume(
                    name=$.appName + '-config',
                    configMapName=$.appName,
                    items=[
                      k8sUtils.generateVolumeItem(key='prometheus.yml', path='prometheus.yml'),
                    ],
                  ),
                ] + (if $.rulesConfig != null then [
                       k8sUtils.generateConfigMapVolume(
                         name=$.appName + '-rule',
                         configMapName=$.appName,
                         items=[
                           k8sUtils.generateVolumeItem(key=key, path=key)
                           for key in std.objectFields($.rulesConfig)
                         ],
                       ),
                     ] else [])
                + (
                  if $.withHomeAssistantToken then [
                    k8sUtils.generateSecretVolume(
                      name='homeassistant-token',
                      secretName='prometheus-homeassistant-secret',
                      items=[
                        k8sUtils.generateVolumeItem(key='token', path='homeassistant_token'),
                      ],
                    ),
                  ] else []
                ),
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
