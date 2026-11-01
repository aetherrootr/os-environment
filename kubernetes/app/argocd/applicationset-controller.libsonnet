local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-applicationset-controller',
  image:: 'quay.io/argoproj/argocd:v3.5.6',
  replicas:: 1,

  local parameterEnv = {
    GRPC_ENABLE_TXT_SERVICE_CONFIG: 'applicationsetcontroller.grpc.enable.txt.service.config',
    ARGOCD_APPLICATIONSET_CONTROLLER_GLOBAL_PRESERVED_ANNOTATIONS: 'applicationsetcontroller.global.preserved.annotations',
    ARGOCD_APPLICATIONSET_CONTROLLER_GLOBAL_PRESERVED_LABELS: 'applicationsetcontroller.global.preserved.labels',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_LEADER_ELECTION: 'applicationsetcontroller.enable.leader.election',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER: 'repo.server',
    ARGOCD_APPLICATIONSET_CONTROLLER_POLICY: 'applicationsetcontroller.policy',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_POLICY_OVERRIDE: 'applicationsetcontroller.enable.policy.override',
    ARGOCD_APPLICATIONSET_CONTROLLER_DEBUG: 'applicationsetcontroller.debug',
    ARGOCD_APPLICATIONSET_CONTROLLER_LOGFORMAT: 'applicationsetcontroller.log.format',
    ARGOCD_APPLICATIONSET_CONTROLLER_LOGLEVEL: 'applicationsetcontroller.log.level',
    ARGOCD_LOG_FORMAT_TIMESTAMP: 'log.format.timestamp',
    ARGOCD_K8S_CLIENT_QPS: 'applicationsetcontroller.k8s.client.qps',
    ARGOCD_K8S_CLIENT_BURST: 'applicationsetcontroller.k8s.client.burst',
    ARGOCD_K8S_CLIENT_MAX_IDLE_CONNECTIONS: 'applicationsetcontroller.k8s.client.max.idle.connections',
    ARGOCD_K8S_TCP_TIMEOUT: 'applicationsetcontroller.k8s.tcp.timeout',
    ARGOCD_K8S_TCP_KEEPALIVE: 'applicationsetcontroller.k8s.tcp.keepalive',
    ARGOCD_K8S_TLS_HANDSHAKE_TIMEOUT: 'applicationsetcontroller.k8s.tls.handshake.timeout',
    ARGOCD_K8S_TCP_IDLE_TIMEOUT: 'applicationsetcontroller.k8s.tcp.idle.timeout',
    ARGOCD_APPLICATIONSET_CONTROLLER_DRY_RUN: 'applicationsetcontroller.dryrun',
    ARGOCD_GIT_MODULES_ENABLED: 'applicationsetcontroller.enable.git.submodule',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_PROGRESSIVE_SYNCS: 'applicationsetcontroller.enable.progressive.syncs',
    ARGOCD_APPLICATIONSET_CONTROLLER_TOKENREF_STRICT_MODE: 'applicationsetcontroller.enable.tokenref.strict.mode',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_NEW_GIT_FILE_GLOBBING: 'applicationsetcontroller.enable.new.git.file.globbing',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_PLAINTEXT: 'applicationsetcontroller.repo.server.plaintext',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_STRICT_TLS: 'applicationsetcontroller.repo.server.strict.tls',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_CA_CERT_PATH: 'applicationsetcontroller.repo.server.ca.cert.path',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_CLIENT_CERT_PATH: 'applicationsetcontroller.repo.server.client.cert.path',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_CLIENT_CERT_KEY_PATH: 'applicationsetcontroller.repo.server.client.cert.key.path',
    ARGOCD_APPLICATIONSET_CONTROLLER_REPO_SERVER_TIMEOUT_SECONDS: 'applicationsetcontroller.repo.server.timeout.seconds',
    ARGOCD_APPLICATIONSET_CONTROLLER_CONCURRENT_RECONCILIATIONS: 'applicationsetcontroller.concurrent.reconciliations.max',
    ARGOCD_APPLICATIONSET_CONTROLLER_NAMESPACES: 'applicationsetcontroller.namespaces',
    ARGOCD_APPLICATIONSET_CONTROLLER_SCM_ROOT_CA_PATH: 'applicationsetcontroller.scm.root.ca.path',
    ARGOCD_APPLICATIONSET_CONTROLLER_ALLOWED_SCM_PROVIDERS: 'applicationsetcontroller.allowed.scm.providers',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_SCM_PROVIDERS: 'applicationsetcontroller.enable.scm.providers',
    ARGOCD_APPLICATIONSET_CONTROLLER_ENABLE_GITHUB_API_METRICS: 'applicationsetcontroller.enable.github.api.metrics',
    ARGOCD_APPLICATIONSET_CONTROLLER_WEBHOOK_PARALLELISM_LIMIT: 'applicationsetcontroller.webhook.parallelism.limit',
    ARGOCD_APPLICATIONSET_CONTROLLER_REQUEUE_AFTER: 'applicationsetcontroller.requeue.after',
    ARGOCD_APPLICATIONSET_CONTROLLER_MAX_RESOURCES_STATUS_COUNT: 'applicationsetcontroller.status.max.resources.count',
  },
  local appEnv = [
    k8sUtils.tk.envVar.withName('NAMESPACE') + {
      valueFrom: {
        fieldRef: {
          fieldPath: 'metadata.namespace',
        },
      },
    },
  ] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='argocd-applicationset-controller',
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
      '/usr/local/bin/argocd-applicationset-controller',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=7000,
        name='webhook',
      ),
      k8sUtils.generateContainerPort(
        containerPort=8080,
        name='metrics',
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
        mountPath='/tmp',
        name='tmp',
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
        mountPath='/home/argocd/params',
        name='argocd-cmd-params-cm',
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

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-applicationset-controller',
    volumes=[
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
            key='applicationsetcontroller.profile.enabled',
            path='profiler.enabled',
          ),
        ],
        optional=true,
      ),
    ],
  ),

  applicationsetController: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-applicationset-controller',
      ports=[
        k8sUtils.generateServicePort(
          name='webhook',
          port=7000,
          protocol='TCP',
          targetPort='webhook',
        ),
        k8sUtils.generateServicePort(
          name='metrics',
          port=8080,
          protocol='TCP',
          targetPort='metrics',
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'applicationset-controller',
        'app.kubernetes.io/name': 'argocd-applicationset-controller',
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
        'app.kubernetes.io/component': 'applicationset-controller',
        'app.kubernetes.io/name': 'argocd-applicationset-controller',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],
}
