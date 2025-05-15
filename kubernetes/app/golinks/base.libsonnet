local k8sUtils = import "utils/k8s-utils.libsonnet";

{
  namespace:: error ("namespace is required"),
  appName:: error ("appName is required"),
  replicas:: 1,
  port:: 8067,

  local nfsName = "service_data",
  local nfsServer = k8sUtils.getNfsUrl(nfsName),
  local nfsPath = k8sUtils.getServiceDataNfsPath(nfsName, $.appName),

  local containerImage = "aethertaberu/golinks:latest",
  local hosts = [k8sUtils.getServiceHostname(serviceName="go"), "go"],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name="http", containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: "10m",
        memory: "16Mi",
      },
      limits: {
        cpu: "200m",
        memory: "256Mi",
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + "-data-nfs",
        mountPath="/data",
      ),
    ],
    env=[
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
            name=$.appName + "-data-nfs",
            nfsServer=nfsServer,
            path=nfsPath,
          ),
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
      withCertManager=false,
    ),
  ]),
}
