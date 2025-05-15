local k = import "common/lib/k.libsonnet";
local tankaUtils = import "common/lib/tanka-utils.libsonnet";

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
                     volumeMounts=null):
    $.tk.container.new(containerName, image)
    + (if args != null then $.tk.container.withArgs(args) else {})
    + (if command != null then $.tk.container.withCommand(command) else {})
    + $.tk.container.resources.withRequests(resources.requests)
    + $.tk.container.resources.withLimits(resources.limits)
    + (if env != null then $.tk.container.withEnv(env) else {})
    + (if ports != null then $.tk.container.withPorts(ports) else {})
    + (if volumeMounts != null then $.tk.container.withVolumeMounts(volumeMounts) else {}),

  generateContainerPort(name=null, containerPort, protocol="TCP"):
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
    restartPolicy="Always",
    initContainers=null,
    nodeSelector=null,
    nodeName=null,
    dnsPolicy="ClusterFirst",
    serviceAccountName=null,
  ):
    $.tk.podSpec.withRestartPolicy(restartPolicy)
    + $.tk.podSpec.withDnsPolicy(dnsPolicy)
    + (if volumes != null then $.tk.podSpec.withVolumes(volumes) else {})
    + (if initContainers != null then $.tk.podSpec.withInitContainers(initContainers) else {})
    + (if nodeSelector != null then $.tk.podSpec.withNodeSelector(nodeSelector) else {})
    + (if nodeName != null then $.tk.podSpec.withNodeName(nodeName) else {})
    + (if serviceAccountName != null then $.tk.podSpec.withServiceAccountName(serviceAccountName) else {}),

  generateService(namespace, appName, ports, type="ClusterIP", clusterIP=null, extraLabels={}):
    $.tk.service.new(
      appName,
      selector={
        app: appName,
      },
      ports=ports
    )
    + $.tk.service.spec.withType(type)
    + (if clusterIP != null then $.tk.service.spec.withClusterIP(clusterIP) else {})
    + defaultMetadata(appName, namespace, extraLabels),

  generateServicePort(name=null, port, targetPort, protocol="TCP", nodePort=null):
    $.tk.servicePort.new(port, targetPort)
    + (if name != null then $.tk.servicePort.withName(name) else {})
    + $.tk.servicePort.withProtocol(protocol)
    + (if nodePort != null then $.tk.servicePort.withNodePort(nodePort) else {}),

  generateIngressPath(urlPath, serviceName, servicePort, pathType="ImplementationSpecific"):
    $.tk.httpIngressPath.withPath(urlPath)
    + $.tk.httpIngressPath.withPathType(pathType)
    + $.tk.httpIngressPath.backend.service.withName(serviceName)
    + $.tk.httpIngressPath.backend.service.port.withNumber(servicePort),

  generateIngress(namespace,
                  appName,
                  serviceName,
                  annotations,
                  port=null,
                  hostnameList=[],
                  certificateName=null,
                  extraRules=[],
                  extraPaths=["/"],
                  extraGeneratedPaths=[],
                  withCertManager=true,
                  extraLabels={},
                  ingressClass="nginx"):
    $.tk.ingress.new(appName)
    + defaultMetadata(appName, namespace, extraLabels)
    + $.tk.ingress.spec.withIngressClassName(ingressClass)
    + $.tk.ingress.metadata.withAnnotations(
      annotations
      + (if withCertManager then {
           "nginx.ingress.kubernetes.io/ssl-redirect": "true",
           "nginx.ingress.kubernetes.io/force-ssl-redirect": "true",
           "nginx.ingress.kubernetes.io/use-port-in-redirects": "true",
         } + (if certificateName == null then {
                "cert-manager.io/cluster-issuer": "letsencrypt-dns-cloudflare",
                "cert-manager.io/common-name": hostnameList[0],
              } else {})
         else {})
    )
    + (if withCertManager then $.tk.ingress.spec.withTls([{
         hosts: hostnameList,
         secretName: if certificateName != null
         then certificateName else appName + "-certificate-tls",
       }]) else {})
    + $.tk.ingress.spec.withRules(extraRules + [
      $.tk.ingressRule.withHost(hostname)
      + $.tk.ingressRule.http.withPaths([
        $.generateIngressPath(urlPath=path, serviceName=serviceName, servicePort=port)
        for path in extraPaths
      ] + extraGeneratedPaths)
      for hostname in hostnameList
    ]),

  getServiceHostname(serviceName):
    serviceName + ".corp.aetherrootr.com",

  getWildcardCertificateName(namespace):
    namespace + "-wildcard-certificate-tls",

  generateNfsVolume(name, nfsServer, path, readOnly=false):
    $.tk.volume.withName(name)
    + $.tk.volume.nfs.withServer(nfsServer)
    + $.tk.volume.nfs.withPath(path)
    + $.tk.volume.nfs.withReadOnly(readOnly),

  generateVolumeMount(name, mountPath, readOnly=false, subPath=null):
    $.tk.volumeMount.new(name, mountPath, readOnly)
    + (if subPath != null then $.tk.volumeMount.withSubPath(subPath) else {}),

  getNfsUrl(nfsName):
    nfsName + "_nfs.corp.aetherrootr.com",

  getServiceDataNfsPath(nfsName, appName):
    "/media/" + nfsName + "/" + std.strReplace(appName, "-", "_"),

  generateConfigMapVolume(name, configMapName, items=[]):
    $.tk.volume.withName(name)
    + $.tk.volume.configMap.withName(configMapName)
    + (if items != [] then $.tk.volume.configMap.withItems(items) else {}),

  generateConfigMapVolumeItem(key, path): {
    key: key,
    path: path,
  },

  importFromHelmChart(projectPath,
                      name,
                      chart,
                      config={}):
    tankaUtils.helm.new(projectPath).template(
      name, chart, config
    ),
}
