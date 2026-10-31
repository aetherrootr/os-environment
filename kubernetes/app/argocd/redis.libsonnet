local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-redis',
  replicas:: 1,
  resources:: {
    requests: {
      cpu: '100m',
      memory: '128Mi',
    },
    limits: {
      cpu: '500m',
      memory: '256Mi',
    },
  },

  local appEnv = [
    k8sUtils.generateSecretEnv(
      name='REDIS_PASSWORD',
      secretName='argocd-redis',
      key='auth',
    ),
  ],

  local containers = k8sUtils.generateContainers(
    containerName='redis',
    image='public.ecr.aws/docker/library/redis:8.2.3-alpine',
    resources=$.resources,
    args=[
      '--save',
      '',
      '--appendonly',
      'no',
      '--requirepass $(REDIS_PASSWORD)',
    ],
    imagePullPolicy='Always',
    ports=[
      k8sUtils.generateContainerPort(
        containerPort=6379,
      ),
    ],
    env=appEnv,
  ) + {
    securityContext: {
      allowPrivilegeEscalation: false,
      capabilities: {
        drop: [
          'ALL',
        ],
      },
      readOnlyRootFilesystem: true,
    },
  },

  local podSpec = k8sUtils.generatePodSpec(
    nodeSelector={
      'kubernetes.io/os': 'linux',
    },
    serviceAccountName='argocd-redis',
  ) + {
    automountServiceAccountToken: false,
    affinity: {
      podAntiAffinity: {
        preferredDuringSchedulingIgnoredDuringExecution: [
          {
            podAffinityTerm: {
              labelSelector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'argocd-redis',
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
    securityContext: {
      runAsNonRoot: true,
      runAsUser: 999,
      seccompProfile: {
        type: 'RuntimeDefault',
      },
    },
  },

  redis: [
    k8sUtils.generateService(
      namespace=$.namespace,
      appName='argocd-redis',
      ports=[
        k8sUtils.generateServicePort(
          name='tcp-redis',
          port=6379,
          targetPort=6379,
        ),
      ],
      selector={ app: $.appName },
      extraLabels={
        'app.kubernetes.io/component': 'redis',
        'app.kubernetes.io/name': 'argocd-redis',
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
        'app.kubernetes.io/component': 'redis',
        'app.kubernetes.io/name': 'argocd-redis',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],
}
