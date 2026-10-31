local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-notifications-controller',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  replicas:: 1,
  resources:: {
    requests: {
      cpu: '50m',
      memory: '64Mi',
    },
    limits: {
      cpu: '200m',
      memory: '128Mi',
    },
  },

  local parameterEnv = {
    ARGOCD_NOTIFICATIONS_CONTROLLER_LOGFORMAT: 'notificationscontroller.log.format',
    ARGOCD_NOTIFICATIONS_CONTROLLER_LOGLEVEL: 'notificationscontroller.log.level',
    ARGOCD_NOTIFICATION_CONTROLLER_PROCESSORS_COUNT: 'notificationscontroller.processors.count',
    ARGOCD_LOG_FORMAT_TIMESTAMP: 'log.format.timestamp',
    ARGOCD_APPLICATION_NAMESPACES: 'application.namespaces',
    ARGOCD_NOTIFICATION_CONTROLLER_SELF_SERVICE_NOTIFICATION_ENABLED: 'notificationscontroller.selfservice.enabled',
    ARGOCD_NOTIFICATION_CONTROLLER_REPO_SERVER_PLAINTEXT: 'notificationscontroller.repo.server.plaintext',
    ARGOCD_NOTIFICATION_CONTROLLER_REPO_SERVER_CA_CERT_PATH: 'notificationscontroller.repo.server.ca.cert.path',
    ARGOCD_NOTIFICATION_CONTROLLER_REPO_SERVER_CLIENT_CERT_PATH: 'notificationscontroller.repo.server.client.cert.path',
    ARGOCD_NOTIFICATION_CONTROLLER_REPO_SERVER_CLIENT_CERT_KEY_PATH: 'notificationscontroller.repo.server.client.cert.key.path',
  },
  local appEnv = [] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='argocd-notifications-controller',
    image=$.image,
    resources=$.resources,
    args=[
      '/usr/local/bin/argocd-notifications',
    ],
    imagePullPolicy='Always',
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/tls',
        name='tls-certs',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/tls',
        name='argocd-repo-server-tls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/mtls',
        name='argocd-repo-server-mtls',
      ),
    ],
  ) + {
    livenessProbe: {
      tcpSocket: {
        port: 9001,
      },
    },
    securityContext: {
      allowPrivilegeEscalation: false,
      capabilities: {
        drop: [
          'ALL',
        ],
      },
      readOnlyRootFilesystem: true,
    },
    workingDir: '/app',
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-notifications-controller',
    volumes=[
      k8sUtils.generateConfigMapVolume(
        name='tls-certs',
        configMapName='argocd-tls-certs-cm',
      ),
      k8sUtils.generateSecretVolume(
        name='argocd-repo-server-tls',
        secretName='argocd-repo-server-tls',
        items=[
          k8sUtils.generateVolumeItem(
            key='tls.crt',
            path='tls.crt',
          ),
          k8sUtils.generateVolumeItem(
            key='tls.key',
            path='tls.key',
          ),
          k8sUtils.generateVolumeItem(
            key='ca.crt',
            path='ca.crt',
          ),
        ],
        optional=true,
      ),
      k8sUtils.generateSecretVolume(
        name='argocd-repo-server-mtls',
        secretName='argocd-repo-server-mtls',
        items=[
          k8sUtils.generateVolumeItem(
            key='client.crt',
            path='client.crt',
          ),
          k8sUtils.generateVolumeItem(
            key='client.key',
            path='client.key',
          ),
          k8sUtils.generateVolumeItem(
            key='server-ca.crt',
            path='server-ca.crt',
          ),
        ],
        optional=true,
      ),
    ],
  ) + {
    securityContext: {
      runAsNonRoot: true,
      seccompProfile: {
        type: 'RuntimeDefault',
      },
    },
  },

  notificationsController: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-notifications-controller-metrics',
      ports=[
        k8sUtils.generateServicePort(
          name='metrics',
          port=9001,
          protocol='TCP',
          targetPort=9001,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'notifications-controller',
        'app.kubernetes.io/name': 'argocd-notifications-controller-metrics',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=podSpec,
      replicas=$.replicas,
      extraLabels={
        'app.kubernetes.io/component': 'notifications-controller',
        'app.kubernetes.io/name': 'argocd-notifications-controller',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ) + {
      spec+: {
        strategy: {
          type: 'Recreate',
        },
      },
    },
  ],
}
