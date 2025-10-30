local k = import 'common/lib/k.libsonnet';
local tankaUtils = import 'common/lib/tanka-utils.libsonnet';

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

  generateConfigMapEnv(name, configMapName, key):
    $.tk.envVar.withName(name)
    + $.tk.envVar.valueFrom.configMapKeyRef.withName(configMapName)
    + $.tk.envVar.valueFrom.configMapKeyRef.withKey(key),

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

  generatePodSpec(
    volumes=null,
    restartPolicy='Always',
    initContainers=null,
    nodeSelector=null,
    nodeName=null,
    dnsPolicy='ClusterFirst',
    serviceAccountName=null,
    hostNetwork=false,
    tolerations=null
  ):
    $.tk.podSpec.withRestartPolicy(restartPolicy)
    + $.tk.podSpec.withDnsPolicy(dnsPolicy)
    + (if volumes != null then $.tk.podSpec.withVolumes(volumes) else {})
    + (if initContainers != null then $.tk.podSpec.withInitContainers(initContainers) else {})
    + (if nodeSelector != null then $.tk.podSpec.withNodeSelector(nodeSelector) else {})
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

  generateIngressPath(urlPath, serviceName, servicePort, pathType='ImplementationSpecific'):
    $.tk.httpIngressPath.withPath(urlPath)
    + $.tk.httpIngressPath.withPathType(pathType)
    + $.tk.httpIngressPath.backend.service.withName(serviceName)
    + $.tk.httpIngressPath.backend.service.port.withNumber(servicePort),

  getAuthProxyOutpostAppName(appName):
    'authentik-proxy-outpost-' + appName,

  getAuthProxyOutpostServiceUrl(appName, namespace):
    'http://' + $.getAuthProxyOutpostAppName(appName) + '.' + namespace + '.svc.cluster.local:9000',

  generateIngress(namespace,
                  appName,
                  serviceName,
                  annotations,
                  port=null,
                  hostnameList=[],
                  certificateName=null,
                  extraRules=[],
                  extraPaths=['/'],
                  extraGeneratedPaths=[],
                  withCertManager=true,
                  extraLabels={},
                  withAuthProxy=false,
                  ingressClass='nginx'):
    $.tk.ingress.new(appName)
    + defaultMetadata(appName, namespace, extraLabels)
    + $.tk.ingress.spec.withIngressClassName(ingressClass)
    + $.tk.ingress.metadata.withAnnotations(
      (if withCertManager then {
         'nginx.ingress.kubernetes.io/ssl-redirect': 'true',
         'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
         'nginx.ingress.kubernetes.io/use-port-in-redirects': 'true',
       } + (if certificateName == null then {
              'cert-manager.io/cluster-issuer': 'letsencrypt-dns-cloudflare',
              'cert-manager.io/common-name': hostnameList[0],
            } else {})
       else {})
      + (if withAuthProxy then {
           'nginx.ingress.kubernetes.io/auth-url': $.getAuthProxyOutpostServiceUrl(appName, namespace) + '/outpost.goauthentik.io/auth/nginx',
           'nginx.ingress.kubernetes.io/auth-signin': 'https://' + hostnameList[0] + '/outpost.goauthentik.io/start?rd=$scheme://$http_host$escaped_request_uri',
           'nginx.ingress.kubernetes.io/auth-response-headers': 'Set-Cookie,X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid',
           'nginx.ingress.kubernetes.io/use-regex': 'true',
         } else {})
      + annotations
    )
    + (if withCertManager then $.tk.ingress.spec.withTls([{
         hosts: hostnameList,
         secretName: if certificateName != null
         then certificateName else appName + '-certificate-tls',
       }]) else {})
    + $.tk.ingress.spec.withRules(extraRules + [
      $.tk.ingressRule.withHost(hostname)
      + $.tk.ingressRule.http.withPaths(
        [
          $.generateIngressPath(urlPath=path, serviceName=serviceName, servicePort=port)
          for path in extraPaths
        ] + extraGeneratedPaths
        + (
          if withAuthProxy then [
            $.generateIngressPath(
              urlPath='/outpost\\.goauthentik\\.io(/|$)(.*)',
              serviceName=$.getAuthProxyOutpostAppName(appName),
              servicePort=9000,
            ),
          ] else []
        )
      )
      for hostname in hostnameList
    ]),

  getServiceHostname(serviceName):
    serviceName + '.corp.aetherrootr.com',

  getWildcardCertificateName(namespace):
    namespace + '-wildcard-certificate-tls',

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

  generateConfigMapVolume(name, configMapName, items=[]):
    $.tk.volume.withName(name)
    + $.tk.volume.configMap.withName(configMapName)
    + (if items != [] then $.tk.volume.configMap.withItems(items) else {}),

  generateVolumeItem(key, path): {
    key: key,
    path: path,
  },

  generateSecretVolume(name, secretName, items=[]):
    $.tk.volume.withName(name)
    + $.tk.volume.secret.withSecretName(secretName)
    + (if items != [] then $.tk.volume.secret.withItems(items) else {}),

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
