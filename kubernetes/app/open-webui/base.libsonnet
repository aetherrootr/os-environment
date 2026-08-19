local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  port:: 8080,
  appSecretName:: $.appName + '-secret',
  image:: 'ghcr.io/open-webui/open-webui:v0.11.0',
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),
  replicas:: 1,

  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],

  local appEnv = std.prune([
    k8sUtils.generateEnv(name='ENABLE_PERSISTENT_CONFIG', value='true'),
    k8sUtils.generateEnv(name='WEBUI_SECRET_KEY_FILE', value='/app/backend/data/.webui_secret_key'),
    k8sUtils.generateEnv(name='WEBUI_URL', value='https://' + hosts[0]),
    k8sUtils.generateEnv(name='ENABLE_RAG_LOCAL_WEB_FETCH', value='True'),
    k8sUtils.generateEnv(name='ENABLE_OAUTH', value='true'),
    k8sUtils.generateEnv(name='ENABLE_OAUTH_SIGNUP', value='true'),
    k8sUtils.generateEnv(name='OAUTH_PROVIDER_NAME', value='Authentik'),
    k8sUtils.generateEnv(name='OAUTH_CLIENT_ID', value='9uaYJc8qRxugssWl8z2Ja73sVC60LwIpQN3oc3P1'),
    k8sUtils.generateSecretEnv(name='OAUTH_CLIENT_SECRET', secretName=$.appSecretName, key='oidc-client-secret'),
    k8sUtils.generateEnv(
      name='OPENID_PROVIDER_URL',
      value='https://authentik.aetherrootr.com/application/o/open-webui/.well-known/openid-configuration',
    ),
    k8sUtils.generateEnv(
      name='OPENID_REDIRECT_URI',
      value='https://' + hosts[0] + '/oauth/oidc/callback',
    ),
    k8sUtils.generateEnv(
      name='OPENID_END_SESSION_ENDPOINT',
      value='https://authentik.aetherrootr.com/application/o/open-webui/end-session/',
    ),
    k8sUtils.generateEnv(name='OAUTH_SCOPES', value='openid email profile'),
    k8sUtils.generateEnv(name='TZ', value='Asia/Shanghai'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=$.image,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '250m',
        memory: '512Mi',
      },
      limits: {
        cpu: '2000m',
        memory: '4Gi',
      },
    },
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-data-pvc',
        mountPath='/app/backend/data',
        subPath=$.appName,
      ),
    ],
  ),

  local deployment = k8sUtils.generateDeployment(
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
              storageClass='service-data',
            ),
          },
        },
      ],
    ),
    replicas=$.replicas,
  ) + {
    spec+: {
      strategy: {
        type: 'Recreate',
      },
    },
  },

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
    deployment,
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName=$.appName,
      serviceName=$.appName,
      annotations={
        'nginx.ingress.kubernetes.io/proxy-body-size': '0',
        'nginx.ingress.kubernetes.io/proxy-buffering': 'off',
        'nginx.ingress.kubernetes.io/proxy-read-timeout': '3600',
        'nginx.ingress.kubernetes.io/proxy-send-timeout': '3600',
      },
      port=$.port,
      hostnameList=hosts,
      certificateName=$.certificateName,
    ),
  ]),
}
