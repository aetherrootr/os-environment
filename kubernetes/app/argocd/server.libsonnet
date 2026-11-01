local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-server',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  replicas:: 1,
  hostname:: k8sUtils.getServiceHostname('argocd'),
  certificateName:: k8sUtils.getWildcardCertificateName($.namespace),

  local parameterEnv = {
    GRPC_ENABLE_TXT_SERVICE_CONFIG: 'server.grpc.enable.txt.service.config',
    ARGOCD_SERVER_INSECURE: 'server.insecure',
    ARGOCD_SERVER_BASEHREF: 'server.basehref',
    ARGOCD_SERVER_ROOTPATH: 'server.rootpath',
    ARGOCD_SERVER_LOGFORMAT: 'server.log.format',
    ARGOCD_SERVER_LOG_LEVEL: 'server.log.level',
    ARGOCD_K8S_CLIENT_QPS: 'server.k8s.client.qps',
    ARGOCD_K8S_CLIENT_BURST: 'server.k8s.client.burst',
    ARGOCD_K8S_CLIENT_MAX_IDLE_CONNECTIONS: 'server.k8s.client.max.idle.connections',
    ARGOCD_K8S_TCP_TIMEOUT: 'server.k8s.tcp.timeout',
    ARGOCD_K8S_TCP_KEEPALIVE: 'server.k8s.tcp.keepalive',
    ARGOCD_K8S_TLS_HANDSHAKE_TIMEOUT: 'server.k8s.tls.handshake.timeout',
    ARGOCD_K8S_TCP_IDLE_TIMEOUT: 'server.k8s.tcp.idle.timeout',
    ARGOCD_SERVER_REPO_SERVER: 'repo.server',
    ARGOCD_SERVER_DEX_SERVER: 'server.dex.server',
    ARGOCD_SERVER_DISABLE_AUTH: 'server.disable.auth',
    ARGOCD_SERVER_ENABLE_GZIP: 'server.enable.gzip',
    ARGOCD_SERVER_REPO_SERVER_TIMEOUT_SECONDS: 'server.repo.server.timeout.seconds',
    ARGOCD_SERVER_X_FRAME_OPTIONS: 'server.x.frame.options',
    ARGOCD_SERVER_CONTENT_SECURITY_POLICY: 'server.content.security.policy',
    ARGOCD_SERVER_REPO_SERVER_PLAINTEXT: 'server.repo.server.plaintext',
    ARGOCD_SERVER_REPO_SERVER_STRICT_TLS: 'server.repo.server.strict.tls',
    ARGOCD_SERVER_REPO_SERVER_CA_CERT_PATH: 'server.repo.server.ca.cert.path',
    ARGOCD_SERVER_REPO_SERVER_CLIENT_CERT_PATH: 'server.repo.server.client.cert.path',
    ARGOCD_SERVER_REPO_SERVER_CLIENT_CERT_KEY_PATH: 'server.repo.server.client.cert.key.path',
    ARGOCD_SERVER_DEX_SERVER_PLAINTEXT: 'server.dex.server.plaintext',
    ARGOCD_SERVER_DEX_SERVER_STRICT_TLS: 'server.dex.server.strict.tls',
    ARGOCD_TLS_MIN_VERSION: 'server.tls.minversion',
    ARGOCD_TLS_MAX_VERSION: 'server.tls.maxversion',
    ARGOCD_TLS_CIPHERS: 'server.tls.ciphers',
    ARGOCD_SERVER_CONNECTION_STATUS_CACHE_EXPIRATION: 'server.connection.status.cache.expiration',
    ARGOCD_SERVER_OIDC_CACHE_EXPIRATION: 'server.oidc.cache.expiration',
    ARGOCD_SERVER_STATIC_ASSETS: 'server.staticassets',
    ARGOCD_APP_STATE_CACHE_EXPIRATION: 'server.app.state.cache.expiration',
    REDIS_SERVER: 'redis.server',
    REDIS_COMPRESSION: 'redis.compression',
    REDISDB: 'redis.db',
    ARGOCD_DEFAULT_CACHE_EXPIRATION: 'server.default.cache.expiration',
    ARGOCD_MAX_COOKIE_NUMBER: 'server.http.cookie.maxnumber',
    ARGOCD_SERVER_LISTEN_ADDRESS: 'server.listen.address',
    ARGOCD_SERVER_METRICS_LISTEN_ADDRESS: 'server.metrics.listen.address',
    ARGOCD_SERVER_OTLP_ADDRESS: 'otlp.address',
    ARGOCD_SERVER_OTLP_INSECURE: 'otlp.insecure',
    ARGOCD_SERVER_OTLP_HEADERS: 'otlp.headers',
    ARGOCD_SERVER_OTLP_ATTRS: 'otlp.attrs',
    ARGOCD_APPLICATION_NAMESPACES: 'application.namespaces',
    ARGOCD_SERVER_ENABLE_PROXY_EXTENSION: 'server.enable.proxy.extension',
    ARGOCD_K8SCLIENT_RETRY_MAX: 'server.k8sclient.retry.max',
    ARGOCD_K8SCLIENT_RETRY_BASE_BACKOFF: 'server.k8sclient.retry.base.backoff',
    ARGOCD_API_CONTENT_TYPES: 'server.api.content.types',
    ARGOCD_SERVER_WEBHOOK_PARALLELISM_LIMIT: 'server.webhook.parallelism.limit',
    ARGOCD_SERVER_GLOB_CACHE_SIZE: 'server.glob.cache.size',
    ARGOCD_SERVER_WEBHOOK_REFRESH_WORKERS: 'server.webhook.refresh.workers',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_NEW_GIT_FILE_GLOBBING: 'applicationsetcontroller.enable.new.git.file.globbing',
    ARGOCD_APPLICATIONSET_CONTROLLER_SCM_ROOT_CA_PATH: 'applicationsetcontroller.scm.root.ca.path',
    ARGOCD_APPLICATIONSET_CONTROLLER_ALLOWED_SCM_PROVIDERS: 'applicationsetcontroller.allowed.scm.providers',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_SCM_PROVIDERS: 'applicationsetcontroller.enable.scm.providers',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_GITHUB_API_METRICS: 'applicationsetcontroller.enable.github.api.metrics',
    ARGOCD_HYDRATOR_ENABLED: 'hydrator.enabled',
    ARGOCD_SYNC_WITH_REPLACE_ALLOWED: 'server.sync.replace.allowed',
  },
  local appEnv = [
    k8sUtils.generateSecretEnv(
      name='REDIS_PASSWORD',
      secretName='argocd-redis',
      key='auth',
    ),
  ] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='argocd-server',
    image=$.image,
    resources={
      requests: {
        cpu: '100m',
        memory: '128Mi',
      },
      limits: {
        cpu: '500m',
        memory: '512Mi',
      },
    },
    args=[
      '/usr/local/bin/argocd-server',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=8080,
      ),
      k8sUtils.generateContainerPort(
        containerPort=8083,
      ),
    ],
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/ssh',
        name='ssh-known-hosts',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/tls',
        name='tls-certs',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/server/tls',
        name='argocd-repo-server-tls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/mtls',
        name='argocd-repo-server-mtls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/dex/tls',
        name='argocd-dex-server-tls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd',
        name='plugins-home',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/tmp',
        name='tmp',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd/params',
        name='argocd-cmd-params-cm',
      ),
    ],
  ) + {
    livenessProbe: {
      httpGet: {
        path: '/healthz?full=true',
        port: 8080,
      },
      initialDelaySeconds: 3,
      periodSeconds: 30,
      timeoutSeconds: 5,
    },
    readinessProbe: {
      httpGet: {
        path: '/healthz',
        port: 8080,
      },
      initialDelaySeconds: 3,
      periodSeconds: 30,
    },
    securityContext: {
      allowPrivilegeEscalation: false,
      capabilities: {
        drop: [
          'ALL',
        ],
      },
      readOnlyRootFilesystem: true,
      runAsNonRoot: true,
      seccompProfile: {
        type: 'RuntimeDefault',
      },
    },
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-server',
    volumes=[
      k8sUtils.tk.volume.withName('plugins-home') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('tmp') + {
        emptyDir: {},
      },
      k8sUtils.generateConfigMapVolume(
        name='ssh-known-hosts',
        configMapName='argocd-ssh-known-hosts-cm',
      ),
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
        name='argocd-dex-server-tls',
        secretName='argocd-dex-server-tls',
        items=[
          k8sUtils.generateVolumeItem(
            key='tls.crt',
            path='tls.crt',
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
      k8sUtils.generateConfigMapVolume(
        name='argocd-cmd-params-cm',
        configMapName='argocd-cmd-params-cm',
        items=[
          k8sUtils.generateVolumeItem(
            key='server.profile.enabled',
            path='profiler.enabled',
          ),
        ],
        optional=true,
      ),
    ],
  ) + {
    affinity: {
      podAntiAffinity: {
        preferredDuringSchedulingIgnoredDuringExecution: [
          {
            podAffinityTerm: {
              labelSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'argocd-server',
                },
              },
              topologyKey: 'kubernetes.io/hostname',
            },
            weight: 100,
          },
          {
            podAffinityTerm: {
              labelSelector: {
                matchLabels: {
                  'app.kubernetes.io/part-of': 'argocd',
                },
              },
              topologyKey: 'kubernetes.io/hostname',
            },
            weight: 5,
          },
        ],
      },
    },
  },

  server: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-server',
      ports=[
        k8sUtils.generateServicePort(
          name='http',
          port=80,
          protocol='TCP',
          targetPort=8080,
        ),
        k8sUtils.generateServicePort(
          name='https',
          port=443,
          protocol='TCP',
          targetPort=8080,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'server',
        'app.kubernetes.io/name': 'argocd-server',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-server-metrics',
      ports=[
        k8sUtils.generateServicePort(
          name='metrics',
          port=8083,
          protocol='TCP',
          targetPort=8083,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'server',
        'app.kubernetes.io/name': 'argocd-server-metrics',
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
        'app.kubernetes.io/component': 'server',
        'app.kubernetes.io/name': 'argocd-server',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
    k8sUtils.generateIngress(
      namespace=$.namespace,
      appName='argocd',
      serviceName=$.appName,
      annotations={
        'nginx.ingress.kubernetes.io/backend-protocol': 'HTTP',
      },
      port=80,
      hostnameList=[$.hostname],
      certificateName=$.certificateName,
    ),
  ],
}
