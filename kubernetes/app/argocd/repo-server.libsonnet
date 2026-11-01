local k8sUtils = import 'utils/k8s-utils.libsonnet';
local tanka = import 'plugins/tanka/base.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-repo-server',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  replicas:: 1,
  local tankaPlugin = tanka { namespace: $.namespace },

  local parameterEnv = {
    GRPC_ENABLE_TXT_SERVICE_CONFIG: 'reposerver.grpc.enable.txt.service.config',
    ARGOCD_REPO_SERVER_LOGFORMAT: 'reposerver.log.format',
    ARGOCD_REPO_SERVER_LOGLEVEL: 'reposerver.log.level',
    ARGOCD_LOG_FORMAT_TIMESTAMP: 'log.format.timestamp',
    ARGOCD_REPO_SERVER_PARALLELISM_LIMIT: 'reposerver.parallelism.limit',
    ARGOCD_REPO_SERVER_LISTEN_ADDRESS: 'reposerver.listen.address',
    ARGOCD_REPO_SERVER_LISTEN_METRICS_ADDRESS: 'reposerver.metrics.listen.address',
    ARGOCD_REPO_SERVER_DISABLE_TLS: 'reposerver.disable.tls',
    ARGOCD_TLS_MIN_VERSION: 'reposerver.tls.minversion',
    ARGOCD_TLS_MAX_VERSION: 'reposerver.tls.maxversion',
    ARGOCD_TLS_CIPHERS: 'reposerver.tls.ciphers',
    ARGOCD_REPO_SERVER_CLIENT_CA_PATH: 'reposerver.client.ca.path',
    ARGOCD_REPO_CACHE_EXPIRATION: 'reposerver.repo.cache.expiration',
    REDIS_SERVER: 'redis.server',
    REDIS_COMPRESSION: 'redis.compression',
    REDISDB: 'redis.db',
    ARGOCD_DEFAULT_CACHE_EXPIRATION: 'reposerver.default.cache.expiration',
    ARGOCD_REPO_SERVER_OTLP_ADDRESS: 'otlp.address',
    ARGOCD_REPO_SERVER_OTLP_INSECURE: 'otlp.insecure',
    ARGOCD_REPO_SERVER_OTLP_HEADERS: 'otlp.headers',
    ARGOCD_REPO_SERVER_OTLP_ATTRS: 'otlp.attrs',
    ARGOCD_REPO_SERVER_MAX_COMBINED_DIRECTORY_MANIFESTS_SIZE: 'reposerver.max.combined.directory.manifests.size',
    ARGOCD_REPO_SERVER_PLUGIN_TAR_EXCLUSIONS: 'reposerver.plugin.tar.exclusions',
    ARGOCD_REPO_SERVER_PLUGIN_USE_MANIFEST_GENERATE_PATHS: 'reposerver.plugin.use.manifest.generate.paths',
    ARGOCD_REPO_SERVER_ALLOW_OUT_OF_BOUNDS_SYMLINKS: 'reposerver.allow.oob.symlinks',
    ARGOCD_REPO_SERVER_STREAMED_MANIFEST_MAX_TAR_SIZE: 'reposerver.streamed.manifest.max.tar.size',
    ARGOCD_REPO_SERVER_STREAMED_MANIFEST_MAX_EXTRACTED_SIZE: 'reposerver.streamed.manifest.max.extracted.size',
    ARGOCD_REPO_SERVER_HELM_MANIFEST_MAX_EXTRACTED_SIZE: 'reposerver.helm.manifest.max.extracted.size',
    ARGOCD_REPO_SERVER_DISABLE_HELM_MANIFEST_MAX_EXTRACTED_SIZE: 'reposerver.disable.helm.manifest.max.extracted.size',
    ARGOCD_REPO_SERVER_OCI_MANIFEST_MAX_EXTRACTED_SIZE: 'reposerver.oci.manifest.max.extracted.size',
    ARGOCD_REPO_SERVER_DISABLE_OCI_MANIFEST_MAX_EXTRACTED_SIZE: 'reposerver.disable.oci.manifest.max.extracted.size',
    ARGOCD_REPO_SERVER_OCI_LAYER_MEDIA_TYPES: 'reposerver.oci.layer.media.types',
    ARGOCD_REVISION_CACHE_LOCK_TIMEOUT: 'reposerver.revision.cache.lock.timeout',
    ARGOCD_GIT_MODULES_ENABLED: 'reposerver.enable.git.submodule',
    ARGOCD_GIT_LS_REMOTE_PARALLELISM_LIMIT: 'reposerver.git.lsremote.parallelism.limit',
    ARGOCD_GIT_REQUEST_TIMEOUT: 'reposerver.git.request.timeout',
    ARGOCD_REPO_SERVER_ENABLE_BUILTIN_GIT_CONFIG: 'reposerver.enable.builtin.git.config',
    ARGOCD_GRPC_MAX_SIZE_MB: 'reposerver.grpc.max.size',
    ARGOCD_REPO_SERVER_INCLUDE_HIDDEN_DIRECTORIES: 'reposerver.include.hidden.directories',
    ARGOCD_HELM_USER_AGENT: 'reposerver.helm.user.agent',
  },
  local appEnv = [
    k8sUtils.generateSecretEnv(
      name='REDIS_PASSWORD',
      secretName='argocd-redis',
      key='auth',
    ),
    k8sUtils.generateConfigMapEnv(
      name='ARGOCD_RECONCILIATION_TIMEOUT',
      configMapName='argocd-cm',
      key='timeout.reconciliation',
      optional=true,
    ),
    k8sUtils.generateEnv(
      name='HELM_CACHE_HOME',
      value='/helm-working-dir',
    ),
    k8sUtils.generateEnv(
      name='HELM_CONFIG_HOME',
      value='/helm-working-dir',
    ),
    k8sUtils.generateEnv(
      name='HELM_DATA_HOME',
      value='/helm-working-dir',
    ),
  ] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='argocd-repo-server',
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
      '/usr/local/bin/argocd-repo-server',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=8081,
      ),
      k8sUtils.generateContainerPort(
        containerPort=8084,
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
        mountPath='/app/config/gpg/source',
        name='gpg-keys',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/gpg/keys',
        name='gpg-keyring',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/tls',
        name='argocd-repo-server-tls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/app/config/reposerver/mtls',
        name='argocd-repo-server-mtls',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/tmp',
        name='tmp',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/helm-working-dir',
        name='helm-working-dir',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd/cmp-server/plugins',
        name='plugins',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/home/argocd/params',
        name='argocd-cmd-params-cm',
      ),
    ],
  ) + {
    livenessProbe: {
      failureThreshold: 3,
      httpGet: {
        path: '/healthz?full=true',
        port: 8084,
      },
      initialDelaySeconds: 30,
      periodSeconds: 30,
      timeoutSeconds: 5,
    },
    readinessProbe: {
      httpGet: {
        path: '/healthz',
        port: 8084,
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
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-repo-server',
    volumes=tankaPlugin.podSpec.volumes + [
      k8sUtils.generateConfigMapVolume(
        name='ssh-known-hosts',
        configMapName='argocd-ssh-known-hosts-cm',
      ),
      k8sUtils.generateConfigMapVolume(
        name='tls-certs',
        configMapName='argocd-tls-certs-cm',
      ),
      k8sUtils.generateConfigMapVolume(
        name='gpg-keys',
        configMapName='argocd-gpg-keys-cm',
      ),
      k8sUtils.tk.volume.withName('gpg-keyring') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('tmp') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('helm-working-dir') + {
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
            key='client-ca.crt',
            path='client-ca.crt',
          ),
        ],
        optional=true,
      ),
      k8sUtils.tk.volume.withName('var-files') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('plugins') + {
        emptyDir: {},
      },
      k8sUtils.generateConfigMapVolume(
        name='argocd-cmd-params-cm',
        configMapName='argocd-cmd-params-cm',
        items=[
          k8sUtils.generateVolumeItem(
            key='reposerver.profile.enabled',
            path='profiler.enabled',
          ),
        ],
        optional=true,
      ),
    ],
    // Prepare the executable for config-management plugins; no Secret initialization.
    initContainers=[
      k8sUtils.generateContainers(
        containerName='copyutil',
        image=$.image,
        resources={
          requests: {
            cpu: '50m',
            memory: '64Mi',
          },
          limits: {
            cpu: '200m',
            memory: '128Mi',
          },
        },
        command=[
          'sh',
          '-c',
        ],
        args=[
          '/bin/cp /usr/local/bin/argocd /var/run/argocd/argocd && /bin/ln -sf /var/run/argocd/argocd /var/run/argocd/argocd-cmp-server',
        ],
        volumeMounts=[
          k8sUtils.generateVolumeMount(
            mountPath='/var/run/argocd',
            name='var-files',
          ),
        ],
      ) + {
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
    ],
  ) + {
    affinity: {
      podAntiAffinity: {
        preferredDuringSchedulingIgnoredDuringExecution: [
          {
            podAffinityTerm: {
              labelSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'argocd-repo-server',
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
    automountServiceAccountToken: false,
    securityContext: {
      fsGroup: 999,
      fsGroupChangePolicy: 'OnRootMismatch',
    },
  },

  repoServer: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-repo-server',
      ports=[
        k8sUtils.generateServicePort(
          name='server',
          port=8081,
          protocol='TCP',
          targetPort=8081,
        ),
        k8sUtils.generateServicePort(
          name='metrics',
          port=8084,
          protocol='TCP',
          targetPort=8084,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'repo-server',
        'app.kubernetes.io/name': 'argocd-repo-server',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=[containers] + tankaPlugin.containers,
      podSpec=podSpec,
      replicas=$.replicas,
      annotations={
        'checksum/tanka-cmp': std.md5(std.manifestJson(tankaPlugin.config[0].data)),
      },
      extraLabels={
        'app.kubernetes.io/component': 'repo-server',
        'app.kubernetes.io/name': 'argocd-repo-server',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],
}
