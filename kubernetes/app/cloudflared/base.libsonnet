local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error ('namespace is required'),
  appName:: 'cloudflared',
  replicas:: 1,
  certificateName:: k8sUtils.getWildcardCertificateName(namespace=$.namespace),

  local containerImage = 'cloudflare/cloudflared:2026.5.2',

  local appEnv = std.prune([
    k8sUtils.generateSecretEnv(name='TUNNEL_TOKEN', secretName='cloudflared-secret', key='tunnel_token'),
  ]),

  local containers = k8sUtils.generateContainers(
    containerName=$.appName,
    image=containerImage,
    resources={
      requests: {
        cpu: '10m',
        memory: '50Mi',
      },
      limits: {
        cpu: '500m',
        memory: '256Mi',
      },
    },
    env=appEnv,
    args=[
      'tunnel',
      '--no-autoupdate',
      '--protocol',
      'http2',
      'run',
    ]
  ),

  apiVersion: 'apps/v1',
  kind: 'list',
  items: std.prune([
    k8sUtils.generateDeployment(
      namespace=$.namespace,
      appName=$.appName,
      containers=containers,
      podSpec=k8sUtils.generatePodSpec(),
      replicas=$.replicas,
    ),
    {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'NetworkPolicy',
      metadata: {
        name: 'restrict-cloudflared-egress',
        namespace: 'cloudflare-tunnel',
      },
      spec: {
        podSelector: {
          matchLabels: {
            app: 'cloudflared',
          },
        },
        policyTypes: [
          'Egress',
        ],
        egress: [
          {
            to: [
              {
                namespaceSelector: {
                  matchLabels: {
                    'kubernetes.io/metadata.name': 'kube-system',
                  },
                },
              },
              {
                ipBlock: {
                  cidr: '10.96.0.0/12',
                },
              },
              {
                ipBlock: {
                  cidr: '10.244.0.0/16',
                },
              },
            ],
            ports: [
              { protocol: 'UDP', port: 53 },
              { protocol: 'TCP', port: 53 },
            ],
          },
          {
            to: [
              {
                ipBlock: {
                  cidr: '0.0.0.0/0',
                  except: [
                    '10.0.0.0/8',
                    '192.168.0.0/16',
                    '172.16.0.0/12',
                  ],
                },
              },
            ],
          },
          {
            to: [
              {
                ipBlock: {
                  cidr: '192.168.8.205/32',
                },
              },
            ],
            ports: [
              { protocol: 'TCP', port: 443 },
            ],
          },
        ],
      },
    },
  ]),
}
