local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  appName:: 'argocd-tanka-cmp',
  image:: 'docker.io/grafana/tanka:0.37.4',
  execTimeout:: '180s',

  local appEnv = [
    k8sUtils.generateEnv(
      name='HOME',
      value='/home/argocd',
    ),
    k8sUtils.generateEnv(
      name='ARGOCD_EXEC_TIMEOUT',
      value=$.execTimeout,
    ),
  ],

  local containers = k8sUtils.generateContainers(
    containerName='tanka-cmp',
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
    command=[
      '/var/run/argocd/argocd-cmp-server',
    ],
    imagePullPolicy='IfNotPresent',
    env=appEnv,
    volumeMounts=[
      k8sUtils.generateVolumeMount(
        name='var-files',
        mountPath='/var/run/argocd',
      ),
      k8sUtils.generateVolumeMount(
        name='plugins',
        mountPath='/home/argocd/cmp-server/plugins',
      ),
      k8sUtils.generateVolumeMount(
        name='tanka-home',
        mountPath='/home/argocd',
      ),
      k8sUtils.generateVolumeMount(
        name='tanka-config',
        mountPath='/home/argocd/cmp-server/config',
        readOnly=true,
      ),
      // Never share /tmp with the repo-server container.
      k8sUtils.generateVolumeMount(
        name='tanka-tmp',
        mountPath='/tmp',
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
      runAsUser: 999,
      runAsGroup: 999,
      seccompProfile: {
        type: 'RuntimeDefault',
      },
    },
  },

  local podSpec = k8sUtils.generatePodSpec(
    volumes=[
      k8sUtils.generateConfigMapVolume(
        name='tanka-config',
        configMapName=$.appName,
      ),
      k8sUtils.tk.volume.withName('tanka-home') + {
        emptyDir: {},
      },
      k8sUtils.tk.volume.withName('tanka-tmp') + {
        emptyDir: {},
      },
    ],
  ),

  config: [
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName=$.appName,
      data={
        // CMP configuration is a file consumed by argocd-cmp-server, not a CRD.
        'plugin.yaml': std.manifestYamlDoc({
          apiVersion: 'argoproj.io/v1alpha1',
          kind: 'ConfigManagementPlugin',
          metadata: {
            name: 'tanka',
          },
          spec: {
            version: 'v1.0',
            init: {
              command: ['/bin/sh', '/home/argocd/cmp-server/config/init.sh'],
            },
            generate: {
              command: ['/bin/sh', '/home/argocd/cmp-server/config/generate.sh'],
            },
            // Explicit opt-in via spec.source.plugin.name=tanka-v1.0.
            preserveFileMode: false,
            provideGitCreds: false,
          },
        }),
        'init.sh': importstr 'init.sh',
        'generate.sh': importstr 'generate.sh',
      },
      labels={
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],

  // The plugin contributes to the existing repo-server Pod.
  containers: [containers],
  podSpec: podSpec,
}
