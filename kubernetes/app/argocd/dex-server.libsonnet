local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-dex-server',
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
    ARGOCD_DEX_SERVER_LOGFORMAT: 'dexserver.log.format',
    ARGOCD_DEX_SERVER_LOGLEVEL: 'dexserver.log.level',
    ARGOCD_LOG_FORMAT_TIMESTAMP: 'log.format.timestamp',
    ARGOCD_DEX_SERVER_DISABLE_TLS: 'dexserver.disable.tls',
    DEX_CONTINUE_ON_CONNECTOR_FAILURE: 'dexserver.connector.failure.continue',
  },
  local appEnv = [] + [
    k8sUtils.generateConfigMapEnv(
      name=name, configMapName='argocd-cmd-params-cm', key=parameterEnv[name], optional=true,
    )
    for name in std.objectFields(parameterEnv)
  ],

  local containers = k8sUtils.generateContainers(
    containerName='dex',
    image='ghcr.io/dexidp/dex:v2.45.1',
    resources=$.resources,
    command=[
      '/shared/argocd-dex',
      'rundex',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=5556,
      ),
      k8sUtils.generateContainerPort(
        containerPort=5557,
      ),
      k8sUtils.generateContainerPort(
        containerPort=5558,
      ),
    ],
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        mountPath='/shared',
        name='static-files',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/tmp',
        name='dexconfig',
      ),
      k8sUtils.generateVolumeMount(
        mountPath='/tls',
        name='argocd-dex-server-tls',
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
      runAsUser: 1001,
      seccompProfile: {
        type: 'RuntimeDefault',
      },
    },
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-dex-server',
    volumes=[
      k8sUtils.tk.volume.withName('static-files') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('dexconfig') + {
        emptyDir: {},
      },
      k8sUtils.generateSecretVolume(
        name='argocd-dex-server-tls',
        secretName='argocd-dex-server-tls',
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
    ],
    // Copy the Argo CD wrapper into the Dex image; no Secret initialization.
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
          '/bin/cp',
          '-n',
          '/usr/local/bin/argocd',
          '/shared/argocd-dex',
        ],
        imagePullPolicy='Always',
        volumeMounts=[
          k8sUtils.generateVolumeMount(
            mountPath='/shared',
            name='static-files',
          ),
          k8sUtils.generateVolumeMount(
            mountPath='/tmp',
            name='dexconfig',
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

  dexServer: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-dex-server',
      ports=[
        k8sUtils.generateServicePort(
          name='http',
          port=5556,
          protocol='TCP',
          targetPort=5556,
        ) + {
          appProtocol: 'TCP',
        },
        k8sUtils.generateServicePort(
          name='grpc',
          port=5557,
          protocol='TCP',
          targetPort=5557,
        ),
        k8sUtils.generateServicePort(
          name='metrics',
          port=5558,
          protocol='TCP',
          targetPort=5558,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'dex-server',
        'app.kubernetes.io/name': 'argocd-dex-server',
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
        'app.kubernetes.io/component': 'dex-server',
        'app.kubernetes.io/name': 'argocd-dex-server',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],
}
