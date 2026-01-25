local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'komga',
  replicas:: 1,
  port:: 25600,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  urlPrefix:: 'library',

  local containerImage = 'gotson/komga:1.23.6',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.urlPrefix)],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '100m',
        memory: '500Mi',
      },
      limits: {
        cpu: '2000m',
        memory: '2Gi',
      },
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-config-pvc',
        mountPath='/config',
        subPath=$.appName,
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/data',
      ),
      k8sUtils.generateVolumeMount(
        name='application-yml',
        mountPath='/config/application.yml',
        subPath='application.yml',
        readOnly=true,
      ),
    ],
    env=[
      k8sUtils.generateEnv('TZ', 'Asia/Shanghai'),
      k8sUtils.generateEnv('JAVA_TOOL_OPTIONS', '-Xmx4g'),
      k8sUtils.generateEnv('KOMGA_OAUTH2_ACCOUNT_CREATION', 'true'),
    ]
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
          k8sUtils.generateSecretVolume(
            name='application-yml',
            secretName='komga-secret',
            items=[
              k8sUtils.generateVolumeItem(key='application.yml', path='application.yml'),
            ],
          ),
          {
            name: $.appName + '-data-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='data0',
              ),
            },
          },
          {
            name: $.appName + '-config-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
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
