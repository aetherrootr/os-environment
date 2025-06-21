local k8sUtils = import 'utils/k8s-utils.libsonnet';
local prometheusDatasource = importstr 'datasource/prometheus.yaml';

{
  namespace:: error ('namespace is required'),
  appName:: error ('appName is required'),
  replicas:: 1,
  port:: 3000,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'grafana/grafana:latest',
  local hosts = [k8sUtils.getServiceHostname(serviceName=$.appName)],


  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    ports=[
      k8sUtils.generateContainerPort(name='http', containerPort=$.port),
    ],
    resources={
      requests: {
        cpu: '250m',
        memory: '750Mi',
      },
      limits: {},
    },
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name=$.appName + '-pvc',
        mountPath='/var/lib/grafana',
        subPath=std.strReplace($.appName, '-', '_'),
      ),
      k8sUtils.generateVolumeMount(
        name=$.appName + '-datasource',
        mountPath='/etc/grafana/provisioning/datasources',
        readOnly=true,
      ),
    ],
    env=[
      k8sUtils.generateEnv(name='GF_SECURITY_ADMIN_USER', value='admin'),
      k8sUtils.generateSecretEnv(name='GF_SECURITY_ADMIN_PASSWORD', secretName='grafana-secret', key='password'),
      k8sUtils.generateEnv(name='GF_AUTH_ANONYMOUS_ENABLED', value='true'),
      k8sUtils.generateEnv(name='GF_AUTH_ANONYMOUS_ORG_ROLE', value='Viewer'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_ENABLED', value='true'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_NAME', value='authentik'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_CLIENT_ID', value='vyrhWCV1TqWfqPMPxKlAUv69eMqSCqGl1vos6M0V'),
      k8sUtils.generateSecretEnv(name='GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET', secretName='grafana-secret', key='oauth-client-secret'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_SCOPES', value='openid profile email'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_AUTH_URL', value='https://authentik.corp.aetherrootr.com/application/o/authorize/'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_TOKEN_URL', value='https://authentik.corp.aetherrootr.com/application/o/token/'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_API_URL', value='https://authentik.corp.aetherrootr.com/application/o/userinfo/'),
      k8sUtils.generateEnv(name='GF_AUTH_SIGNOUT_REDIRECT_URL', value='https://authentik.corp.aetherrootr.com/application/o/grafana/end-session/'),
      k8sUtils.generateEnv(name='GF_AUTH_OAUTH_AUTO_LOGIN', value='true'),
      k8sUtils.generateEnv(name='GF_SERVER_ROOT_URL', value='https://grafana.corp.aetherrootr.com'),
      k8sUtils.generateEnv(name='GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH', value="contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'"),
    ],
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName + '-datasource',
      data={
        'prometheus.yaml': prometheusDatasource,
      }
    ),
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
          {
            name: $.appName + '-pvc',
            persistentVolumeClaim: {
              claimName: k8sUtils.getPVCName(
                namespace=$.namespace,
                storageClass='service-data',
              ),
            },
          },
          k8sUtils.generateConfigMapVolume(
            name=$.appName + '-datasource',
            configMapName=$.appName + '-datasource'
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
