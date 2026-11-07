local k = import 'common/lib/k.libsonnet';
local tankaUtils = import 'common/lib/tanka-utils.libsonnet';
local gatewayUtils = import 'gateway-utils.libsonnet';

{
  local defaultMetadata(appName, namespace, extraLabels={}) = {
    metadata+: {
      labels: {
        app: appName,
      } + extraLabels,
      namespace: namespace,
    },
  },


  tk: (k.core.v1) + (k.apps.v1) + (k.batch.v1) + (k.networking.v1),


  generateEnv(name, value):
    $.tk.envVar.new(name, value),

  generateSecretEnv(name, secretName, key):
    $.tk.envVar.withName(name)
    + $.tk.envVar.valueFrom.secretKeyRef.withName(secretName)
    + $.tk.envVar.valueFrom.secretKeyRef.withKey(key),

  generateConfigMap(namespace, appName, data, labels={}):
    $.tk.configMap.new(appName, data) +
    defaultMetadata(appName, namespace, labels),

  generateConfigMapEnv(name, configMapName, key, optional=null):
    $.tk.envVar.withName(name)
    + $.tk.envVar.valueFrom.configMapKeyRef.withName(configMapName)
    + $.tk.envVar.valueFrom.configMapKeyRef.withKey(key)
    + (if optional != null then $.tk.envVar.valueFrom.configMapKeyRef.withOptional(optional) else {}),

  generateContainers(containerName,
                     image,
                     resources,
                     args=null,
                     command=null,
                     env=null,
                     ports=null,
                     volumeMounts=null,
                     imagePullPolicy='IfNotPresent',
                     privileged=false):
    $.tk.container.new(containerName, image)
    + $.tk.container.withImagePullPolicy(imagePullPolicy)
    + (if args != null then $.tk.container.withArgs(args) else {})
    + (if command != null then $.tk.container.withCommand(command) else {})
    + $.tk.container.resources.withRequests(resources.requests)
    + $.tk.container.resources.withLimits(resources.limits)
    + (if env != null then $.tk.container.withEnv(env) else {})
    + (if ports != null then $.tk.container.withPorts(ports) else {})
    + (if volumeMounts != null then $.tk.container.withVolumeMounts(volumeMounts) else {})
    + (if privileged != false then $.tk.container.securityContext.withPrivileged(privileged) else {}),

  generateContainerPort(name=null, containerPort, protocol='TCP'):
    $.tk.containerPort.new(containerPort)
    + (if name != null then $.tk.containerPort.withName(name) else {})
    + $.tk.containerPort.withProtocol(protocol),

  generateDeployment(namespace,
                     appName,
                     podSpec,
                     containers,
                     replicas=1,
                     annotations=null,
                     extraLabels={}):
    $.tk.deployment.new(appName, replicas, containers)
    + defaultMetadata(appName, namespace, extraLabels)
    + $.tk.deployment.spec.selector.withMatchLabels({ app: appName })
    + $.tk.deployment.spec.template.metadata.withLabels({ app: appName } + extraLabels)
    + (if annotations != null then $.tk.deployment.spec.template.metadata.withAnnotations(annotations) else {})
    + {
      spec+: {
        template+: {
          spec+: podSpec,
        },
      },
    },

  generateStatefulSet(namespace,
                      appName,
                      podSpec,
                      containers,
                      replicas=1,
                      annotations=null,
                      extraLabels={}):
    $.tk.statefulSet.new(appName, replicas, containers)
    + defaultMetadata(appName, namespace, extraLabels)
    + $.tk.statefulSet.spec.selector.withMatchLabels({ app: appName })
    + $.tk.statefulSet.spec.template.metadata.withLabels({ app: appName } + extraLabels)
    + (if annotations != null then $.tk.statefulSet.spec.template.metadata.withAnnotations(annotations) else {})
    + {
      spec+: {
        template+: {
          spec+: podSpec,
        },
      },
    },

  generateRequiredNodeAffinity(labels): {
    nodeAffinity: {
      requiredDuringSchedulingIgnoredDuringExecution: {
        nodeSelectorTerms: [{
          matchExpressions: [
            {
              key: key,
              operator: 'In',
              values: [labels[key]],
            }
            for key in std.objectFields(labels)
          ],
        }],
      },
    },
  },

  generatePodSpec(
    volumes=null,
    restartPolicy='Always',
    initContainers=null,
    nodeSelector=null,
    nodeName=null,
    dnsPolicy='ClusterFirst',
    serviceAccountName=null,
    hostNetwork=false,
    tolerations=null,
    affinity=null
  ):
    $.tk.podSpec.withRestartPolicy(restartPolicy)
    + $.tk.podSpec.withDnsPolicy(dnsPolicy)
    + (if volumes != null then $.tk.podSpec.withVolumes(volumes) else {})
    + (if initContainers != null then $.tk.podSpec.withInitContainers(initContainers) else {})
    + (if nodeSelector != null then $.tk.podSpec.withNodeSelector(nodeSelector) else {})
    + (if affinity != null then { affinity: affinity } else {})
    + (if nodeName != null then $.tk.podSpec.withNodeName(nodeName) else {})
    + (if serviceAccountName != null then $.tk.podSpec.withServiceAccountName(serviceAccountName) else {})
    + (if hostNetwork == true then $.tk.podSpec.withHostNetwork(hostNetwork) else {})
    + (if tolerations != null then $.tk.podSpec.withTolerations(tolerations) else {}),

  generateService(namespace,
                  appName,
                  ports,
                  type='ClusterIP',
                  clusterIP=null,
                  extraLabels={},
                  selector={ app: appName }):
    $.tk.service.new(
      appName,
      selector=selector,
      ports=ports
    )
    + $.tk.service.spec.withType(type)
    + (if clusterIP != null then $.tk.service.spec.withClusterIP(clusterIP) else {})
    + defaultMetadata(appName, namespace, extraLabels),

  generateServicePort(name=null, port, targetPort, protocol='TCP', nodePort=null):
    $.tk.servicePort.new(port, targetPort)
    + (if name != null then $.tk.servicePort.withName(name) else {})
    + $.tk.servicePort.withProtocol(protocol)
    + (if nodePort != null then $.tk.servicePort.withNodePort(nodePort) else {}),

  getAuthProxyOutpostAppName(appName):
    'authentik-proxy-outpost-' + appName,

  getAuthProxyOutpostServiceUrl(appName, namespace):
    'http://' + $.getAuthProxyOutpostAppName(appName) + '.' + namespace + '.svc.cluster.local:9000',

  generateHTTPRoutes(namespace, appName, serviceName, port, hostnameList,
                     tls=true, withAuthProxy=false, basicAuthSecret=null,
                     rules=null, requestTimeout='0s', extraLabels={}):
    gatewayUtils.routes(
      namespace, appName, serviceName, port, hostnameList,
      tls, withAuthProxy, basicAuthSecret, rules, requestTimeout, extraLabels
    ),

  getServiceHostname(serviceName):
    serviceName + '.corp.aetherrootr.com',

  getPVCName(storageClass, namespace):
    storageClass + '-' + namespace + '-pvc',

  generateNfsVolume(name, nfsServer, path, readOnly=false):
    $.tk.volume.withName(name)
    + $.tk.volume.nfs.withServer(nfsServer)
    + $.tk.volume.nfs.withPath(path)
    + $.tk.volume.nfs.withReadOnly(readOnly),

  generateHostPathVolume(name, path, type):
    $.tk.volume.withName(name)
    + $.tk.volume.hostPath.withPath(path)
    + $.tk.volume.hostPath.withType(type),

  generateVolumeMount(name, mountPath, readOnly=false, subPath=null):
    $.tk.volumeMount.new(name, mountPath, readOnly)
    + (if subPath != null then $.tk.volumeMount.withSubPath(subPath) else {}),

  generateConfigMapVolume(name, configMapName, items=[], optional=null):
    $.tk.volume.withName(name)
    + $.tk.volume.configMap.withName(configMapName)
    + (if items != [] then $.tk.volume.configMap.withItems(items) else {})
    + (if optional != null then $.tk.volume.configMap.withOptional(optional) else {}),

  generateVolumeItem(key, path): {
    key: key,
    path: path,
  },

  generateSecretVolume(name, secretName, items=[], optional=null):
    $.tk.volume.withName(name)
    + $.tk.volume.secret.withSecretName(secretName)
    + (if items != [] then $.tk.volume.secret.withItems(items) else {})
    + (if optional != null then $.tk.volume.secret.withOptional(optional) else {}),

  importFromHelmChart(projectPath,
                      name,
                      chart,
                      config={}):
    tankaUtils.helm.new(projectPath).template(
      name, chart, config
    ),

  generateCronJob(namespace,
                  appName,
                  jobSpec,
                  schedule,
                  containers,
                  extraLabels={}):
    $.tk.cronJob.new(appName, schedule, containers)
    + defaultMetadata(appName, namespace, extraLabels)
    + {
      spec+: jobSpec,
    },

  generateCronJobSpec(appName,
                      podSpec,
                      extraLabels={},
                      timeZone='Asia/Shanghai',
                      concurrencyPolicy='Forbid',
                      failedJobsHistoryLimit=null,
                      successfulJobsHistoryLimit=null,
                      startingDeadlineSeconds=null,
                      suspend=false,
                      backoffLimit=3,
                      restartPolicy='OnFailure'):
    $.tk.cronJobSpec.jobTemplate.metadata.withLabels({ app: appName } + extraLabels)
    + $.tk.cronJobSpec.jobTemplate.spec.template.metadata.withLabels({ app: appName } + extraLabels)
    + $.tk.cronJobSpec.withTimeZone(timeZone)
    + $.tk.cronJobSpec.withConcurrencyPolicy(concurrencyPolicy)
    + $.tk.cronJobSpec.jobTemplate.spec.withBackoffLimit(backoffLimit)
    + (if failedJobsHistoryLimit != null then $.tk.cronJobSpec.withFailedJobsHistoryLimit(failedJobsHistoryLimit) else {})
    + (if successfulJobsHistoryLimit != null then $.tk.cronJobSpec.withSuccessfulJobsHistoryLimit(successfulJobsHistoryLimit) else {})
    + (if startingDeadlineSeconds != null then $.tk.cronJobSpec.withStartingDeadlineSeconds(startingDeadlineSeconds) else {})
    + (if suspend != false then $.tk.cronJobSpec.withSuspend(suspend) else {})
    + {
      jobTemplate+: {
        spec+: {
          template+: {
            spec+: podSpec
                   { restartPolicy: restartPolicy },
          },
        },
      },
    },
}
