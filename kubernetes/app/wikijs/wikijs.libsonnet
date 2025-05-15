local k8sUtils = import "utils/k8s-utils.libsonnet";

{
  namespace:: error ("namespace is required"),
  appName:: error ("appName is required"),
  databaseHost:: error ("databaseHost is required"),
  databasePort:: error ("databasePort is required"),
  databaseName:: error ("databaseName is required"),
  databaseUser:: error ("databaseUser is required"),
  databasePasswordSecretName:: error ("databasePasswordSecretName is required"),
  replicas:: 1,
  port:: 3000,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local nfsName = "service_data",
  local nfsServer = k8sUtils.getNfsUrl(nfsName),
  local nfsPath = k8sUtils.getServiceDataNfsPath(nfsName, $.appName) + "/token",

  local hosts = [k8sUtils.getServiceHostname(serviceName="wiki")],

  local containerImage = "ghcr.io/requarks/wiki:2",
  local initContainerImage = "busybox:1.35.0",


  local appEnv = std.prune([
    k8sUtils.generateEnv(name="DB_TYPE", value="postgres"),
    k8sUtils.generateEnv(name="DB_HOST", value=$.databaseHost),
    k8sUtils.generateEnv(name="DB_PORT", value=std.toString($.databasePort)),
    k8sUtils.generateEnv(name="DB_NAME", value=$.databaseName),
    k8sUtils.generateEnv(name="DB_USER", value=$.databaseUser),
    k8sUtils.generateSecretEnv(name="DB_PASS", secretName=$.databasePasswordSecretName, key="password"),
    // k8sUtils.generateEnv(name="POSTGRES_PASSWORD", value="wikijsrocks"),
  ]),


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name="http", containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: "100m",
        memory: "256Mi",
      },
      limits: {
        cpu: "500m",
        memory: "512Mi",
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(name=$.appName, mountPath="/token"),
    ],
  ),

  wikijs: std.prune([
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
          k8sUtils.generateNfsVolume(name=$.appName, nfsServer=nfsServer, path=nfsPath),
        ],
        initContainers=[
          k8sUtils.generateContainers(
            containerName="wait-for-postgres",
            image=initContainerImage,
            command=["/bin/sh", "-c"],
            args=[
              "until nc -z " + $.databaseHost + " " + std.toString($.databasePort) +
              "; do echo waiting for " + $.databaseHost + ":" + std.toString($.databasePort) +
              "; sleep 2; done",
            ],
            resources={
              requests: {
                cpu: "10m",
                memory: "10Mi",
              },
              limits: {
                cpu: "10m",
                memory: "10Mi",
              },
            },
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
      certificateName=$.certificateName,
    ),
  ]),
}
