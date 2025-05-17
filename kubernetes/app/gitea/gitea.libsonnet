local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  databaseHost:: error ('databaseHost is required'),
  databasePort:: error ('databasePort is required'),
  databaseName:: error ('databaseName is required'),
  databaseUser:: error ('databaseUser is required'),
  databasePasswordSecretName:: error ('databasePasswordSecretName is required'),
  replicas:: 1,
  port:: 3000,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local hosts = [k8sUtils.getServiceHostname(serviceName='gitea')],

  local containerImage = 'docker.gitea.com/gitea:1.23.8',
  local initContainerImage = 'busybox:1.35.0',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='USER_UID', value='1000'),
    k8sUtils.generateEnv(name='USER_GID', value='1000'),
    k8sUtils.generateEnv(name='GITEA__database__DB_TYPE', value='postgres'),
    k8sUtils.generateEnv(name='GITEA__database__HOST', value=$.databaseHost + ':' + std.toString($.databasePort)),
    k8sUtils.generateEnv(name='GITEA__database__NAME', value=$.databaseName),
    k8sUtils.generateEnv(name='GITEA__database__USER', value=$.databaseUser),
    k8sUtils.generateSecretEnv(name='GITEA__database__PASSWD', secretName=$.databasePasswordSecretName, key='password'),
    k8sUtils.generateEnv(name='DISABLE_SSH', value='false'),
    k8sUtils.generateEnv(name='START_SSH_SERVER', value='true'),
  ]),


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
      k8sUtils.generateContainerPort(name='ssh', containerPort=22),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '500m',
        memory: '512Mi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name='localtime',
        mountPath='/etc/localtime',
        readOnly=true,
      ),
      k8sUtils.generateVolumeMount(
        name='timezone',
        mountPath='/etc/timezone',
        readOnly=true,
      ),
    ],
  ),

  gitea: std.prune([
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName + '-ssh',
      ports=[
        k8sUtils.generateServicePort(name='ssh', port=22, targetPort=22, nodePort=30022),
      ],
      type='NodePort',
      selector={
        app: $.appName,
      },
    ),
    k8sUtils.generateService(
      namespace=$.namespace,
      appName=$.appName + '-web',
      ports=[
        k8sUtils.generateServicePort(name='http', port=$.port, targetPort=$.port),
      ],
      selector={
        app: $.appName,
      },
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        volumes=[
          {
            name: $.appName + '-data-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='data1',
              ),
            },
          },
          k8sUtils.generateHostPathVolume(
            name='timezone',
            path='/etc/timezone',
            type='File',
          ),
          k8sUtils.generateHostPathVolume(
            name='localtime',
            path='/etc/localtime',
            type='File',
          ),
        ],
        initContainers=[
          k8sUtils.generateContainers(
            containerName='wait-for-postgres',
            image=initContainerImage,
            command=['/bin/sh', '-c'],
            args=[
              'until nc -z ' + $.databaseHost + ' ' + std.toString($.databasePort) +
              '; do echo waiting for ' + $.databaseHost + ':' + std.toString($.databasePort) +
              '; sleep 2; done',
            ],
            resources={
              requests: {
                cpu: '100m',
                memory: '128Mi',
              },
              limits: {
                cpu: '1000m',
                memory: '1Gi',
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
      serviceName=$.appName + '-web',
      annotations={},
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
