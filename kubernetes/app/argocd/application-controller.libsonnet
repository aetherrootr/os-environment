local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-application-controller',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  replicas:: 1,

  local parameterEnv = {
    GRPC_ENABLE_TXT_SERVICE_CONFIG: 'controller.grpc.enable.txt.service.config',
    ARGOCD_REPO_ERROR_GRACE_PERIOD_SECONDS: 'controller.repo.error.grace.period.seconds',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER: 'repo.server',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_TIMEOUT_SECONDS: 'controller.repo.server.timeout.seconds',
    ARGOCD_APPLICATION_CONTROLLER_STATUS_PROCESSORS: 'controller.status.processors',
    ARGOCD_APPLICATION_CONTROLLER_OPERATION_PROCESSORS: 'controller.operation.processors',
    ARGOCD_APPLICATION_CONTROLLER_HYDRATION_PROCESSORS: 'controller.hydration.processors',
    ARGOCD_APPLICATION_CONTROLLER_LOGFORMAT: 'controller.log.format',
    ARGOCD_APPLICATION_CONTROLLER_LOGLEVEL: 'controller.log.level',
    ARGOCD_LOG_FORMAT_TIMESTAMP: 'log.format.timestamp',
    ARGOCD_K8S_CLIENT_QPS: 'controller.k8s.client.qps',
    ARGOCD_K8S_CLIENT_BURST: 'controller.k8s.client.burst',
    ARGOCD_K8S_CLIENT_MAX_IDLE_CONNECTIONS: 'controller.k8s.client.max.idle.connections',
    ARGOCD_K8S_TCP_TIMEOUT: 'controller.k8s.tcp.timeout',
    ARGOCD_K8S_TCP_KEEPALIVE: 'controller.k8s.tcp.keepalive',
    ARGOCD_K8S_TLS_HANDSHAKE_TIMEOUT: 'controller.k8s.tls.handshake.timeout',
    ARGOCD_K8S_TCP_IDLE_TIMEOUT: 'controller.k8s.tcp.idle.timeout',
    ARGOCD_APPLICATION_CONTROLLER_METRICS_CACHE_EXPIRATION: 'controller.metrics.cache.expiration',
    ARGOCD_APPLICATION_CONTROLLER_SELF_HEAL_TIMEOUT_SECONDS: 'controller.self.heal.timeout.seconds',
    ARGOCD_APPLICATION_CONTROLLER_SELF_HEAL_BACKOFF_TIMEOUT_SECONDS: 'controller.self.heal.backoff.timeout.seconds',
    ARGOCD_APPLICATION_CONTROLLER_SELF_HEAL_BACKOFF_FACTOR: 'controller.self.heal.backoff.factor',
    ARGOCD_APPLICATION_CONTROLLER_SELF_HEAL_BACKOFF_CAP_SECONDS: 'controller.self.heal.backoff.cap.seconds',
    ARGOCD_APPLICATION_CONTROLLER_SELF_HEAL_BACKOFF_COOLDOWN_SECONDS: 'controller.self.heal.backoff.cooldown.seconds',
    ARGOCD_SYNC_WAVE_DELAY: 'controller.sync.wave.delay.seconds',
    ARGOCD_APPLICATION_CONTROLLER_SYNC_TIMEOUT: 'controller.sync.timeout.seconds',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_PLAINTEXT: 'controller.repo.server.plaintext',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_STRICT_TLS: 'controller.repo.server.strict.tls',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_CA_CERT_PATH: 'controller.repo.server.ca.cert.path',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_CLIENT_CERT_PATH: 'controller.repo.server.client.cert.path',
    ARGOCD_APPLICATION_CONTROLLER_REPO_SERVER_CLIENT_CERT_KEY_PATH: 'controller.repo.server.client.cert.key.path',
    ARGOCD_APPLICATION_CONTROLLER_PERSIST_RESOURCE_HEALTH: 'controller.resource.health.persist',
    ARGOCD_APP_STATE_CACHE_EXPIRATION: 'controller.app.state.cache.expiration',
    REDIS_SERVER: 'redis.server',
    REDIS_COMPRESSION: 'redis.compression',
    REDISDB: 'redis.db',
    ARGOCD_DEFAULT_CACHE_EXPIRATION: 'controller.default.cache.expiration',
    ARGOCD_APPLICATION_CONTROLLER_OTLP_ADDRESS: 'otlp.address',
    ARGOCD_APPLICATION_CONTROLLER_OTLP_INSECURE: 'otlp.insecure',
    ARGOCD_APPLICATION_CONTROLLER_OTLP_HEADERS: 'otlp.headers',
    ARGOCD_APPLICATION_CONTROLLER_OTLP_ATTRS: 'otlp.attrs',
    ARGOCD_APPLICATION_NAMESPACES: 'application.namespaces',
    ARGOCD_CONTROLLER_SHARDING_ALGORITHM: 'controller.sharding.algorithm',
    ARGOCD_APPLICATION_CONTROLLER_KUBECTL_PARALLELISM_LIMIT: 'controller.kubectl.parallelism.limit',
    ARGOCD_K8SCLIENT_RETRY_MAX: 'controller.k8sclient.retry.max',
    ARGOCD_K8SCLIENT_RETRY_BASE_BACKOFF: 'controller.k8sclient.retry.base.backoff',
    ARGOCD_APPLICATION_CONTROLLER_SERVER_SIDE_DIFF: 'controller.diff.server.side',
    ARGOCD_IGNORE_NORMALIZER_JQ_TIMEOUT: 'controller.ignore.normalizer.jq.timeout',
    ARGOCD_HYDRATOR_ENABLED: 'hydrator.enabled',
    ARGOCD_CLUSTER_CACHE_BATCH_EVENTS_PROCESSING: 'controller.cluster.cache.batch.events.processing',
    ARGOCD_CLUSTER_CACHE_EVENTS_PROCESSING_INTERVAL: 'controller.cluster.cache.events.processing.interval',
    ARGOCD_APPLICATION_CONTROLLER_COMMIT_SERVER: 'commit.server',
  },
  local appEnv = [
    k8sUtils.generateSecretEnv(
      name='REDIS_PASSWORD',
      secretName='argocd-redis',
      key='auth',
    ),
    k8sUtils.generateEnv(
      name='ARGOCD_CONTROLLER_REPLICAS',
      value='1',
    ),
    k8sUtils.generateConfigMapEnv(
      name='ARGOCD_RECONCILIATION_TIMEOUT',
      configMapName='argocd-cm',
      key='timeout.reconciliation',
      optional=true,
    ),
    k8sUtils.generateConfigMapEnv(
      name='ARGOCD_HARD_RECONCILIATION_TIMEOUT',
      configMapName='argocd-cm',
      key='timeout.hard.reconciliation',
      optional=true,
    ),
    k8sUtils.generateConfigMapEnv(
      name='ARGOCD_RECONCILIATION_JITTER',
      configMapName='argocd-cm',
      key='timeout.reconciliation.jitter',
      optional=true,
    ),
    k8sUtils.generateEnv(
      name='KUBECACHEDIR',
      value='/tmp/kubecache',
    ),
  ] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='argocd-application-controller',
    image=$.image,
    resources={
      requests: {
        cpu: '100m',
        memory: '256Mi',
      },
      limits: {
        cpu: '1000m',
        memory: '1Gi',
      },
    },
    args=[
      '/usr/local/bin/argocd-application-controller',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=8082,
      ),
    ],
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/controller/tls',
        name='argocd-repo-server-tls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/mtls',
        name='argocd-repo-server-mtls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd',
        name='argocd-home',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd/params',
        name='argocd-cmd-params-cm',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/tmp',
        name='argocd-application-controller-tmp',
      ),
    ],
  ) + {
    readinessProbe: {
      httpGet: {
        path: '/healthz',
        port: 8082,
      },
      initialDelaySeconds: 5,
      periodSeconds: 10,
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
    workingDir: '/home/argocd',
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-application-controller',
    volumes=[
      k8sUtils.tk.volume.withName('argocd-home') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('argocd-application-controller-tmp') + {
        emptyDir: {},
      },
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
      k8sUtils.generateConfigMapVolume(
        name='argocd-cmd-params-cm',
        configMapName='argocd-cmd-params-cm',
        items=[
          k8sUtils.generateVolumeItem(
            key='controller.profile.enabled',
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
                  'app.kubernetes.io/name': 'argocd-application-controller',
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

  applicationController: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-metrics',
      ports=[
        k8sUtils.generateServicePort(
          name='metrics',
          port=8082,
          protocol='TCP',
          targetPort=8082,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'metrics',
        'app.kubernetes.io/name': 'argocd-metrics',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
    k8sUtils.generateStatefulSet(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=podSpec,
      replicas=$.replicas,
      extraLabels={
        'app.kubernetes.io/component': 'application-controller',
        'app.kubernetes.io/name': 'argocd-application-controller',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ) + {
      spec+: {
        serviceName: 'argocd-application-controller',
      },
    },
  ],
}
