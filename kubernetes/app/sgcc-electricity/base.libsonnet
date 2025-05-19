local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'sgcc-electricity',
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'registry.cn-hangzhou.aliyuncs.com/arcw/sgcc_electricity:latest',

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='SET_CONTAINER_TIMEZONE', value='true'),
    k8sUtils.generateEnv(name='CONTAINER_TIMEZONE', value='Asia/Shanghai'),
    k8sUtils.generateSecretEnv(name='PHONE_NUMBER', secretName='sgcc-electricity-secret', key='phone-number'),
    k8sUtils.generateSecretEnv(name='PASSWORD', secretName='sgcc-electricity-secret', key='password'),
    k8sUtils.generateEnv(name='IGNORE_USER_ID', value=''),
    k8sUtils.generateEnv(name='ENABLE_DATABASE_STORAGE', value='True'),
    k8sUtils.generateEnv(name='DB_NAME', value='homeassistant.db'),
    k8sUtils.generateEnv(name='HASS_URL', value='https://ha.corp.aetherrootr.com/'),
    k8sUtils.generateSecretEnv(name='HASS_TOKEN', secretName='sgcc-electricity-secret', key='hass-token'),
    k8sUtils.generateEnv(name='JOB_START_TIME', value='07:00'),
    k8sUtils.generateEnv(name='RETRY_WAIT_TIME_OFFSET_UNIT', value='15'),
    k8sUtils.generateEnv(name='DATA_RETENTION_DAYS', value='7'),
    k8sUtils.generateEnv(name='RECHARGE_NOTIFY', value='Flase'),
    k8sUtils.generateEnv(name='BALANCE', value='0'),
    k8sUtils.generateEnv(name='PUSHPLUS_TOKEN', value=''),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
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
    env=appEnv,
    command=['python3', 'main.py'],
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-pvc',
        mountPath='/data',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
    ],
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(
        {
          name: $.appName + '-pvc',
          persistentVolumeClaim: {
            claimName: k8sUtils.getPVCName(
              namespace=$.namespace,
              storageClass='service-data',
            ),
          },
        },
      ),
      replicas=$.replicas,
    ),
  ]),
}
