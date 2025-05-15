local k8sUtils = import "utils/k8s-utils.libsonnet";

{
  namespace:: error ("namespace is required"),
  appName:: error ("appName is required"),
  replicas:: 1,
  port:: 8080,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local configNfsName = "service_data",
  local configNfsServer = k8sUtils.getNfsUrl(configNfsName),
  local configNfsPath = k8sUtils.getServiceDataNfsPath(configNfsName, $.appName),
  local dataNfsName = "data0",
  local dataNfsServer = k8sUtils.getNfsUrl(dataNfsName),
  local dataNfsPath = "/mnt/data0",

  local containerImage = "hurlenko/filebrowser:latest",
  local hosts = [k8sUtils.getServiceHostname(serviceName="files")],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name="http", containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: "100m",
        memory: "128Mi",
      },
      limits: {
        cpu: "500m",
        memory: "1Gi",
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + "-config-nfs",
        mountPath="/config",
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + "-data-nfs",
        mountPath="/data",
      )
    ],
    env=[
      k8sUtils.generateEnv("FB_BASEURL", "/filebrowser"),
      k8sUtils.generateEnv("TZ", "Asia/Shanghai"),
    ]
  ),

  apiVersion: "apps/v1",
  kind: "list",
  items: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName,
      ports=[
        k8sUtils.generateServicePort(name="http", port=$.port, targetPort=$.port),
      ],
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          k8sUtils.generateNfsVolume(
            name=$.appName + "-config-nfs",
            nfsServer=configNfsServer,
            path=configNfsPath,
          ),
          k8sUtils.generateNfsVolume(
            name=$.appName + "-data-nfs",
            nfsServer=dataNfsServer,
            path=dataNfsPath,
          )
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
