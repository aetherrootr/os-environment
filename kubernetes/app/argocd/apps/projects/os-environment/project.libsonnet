{
  projectName: 'os-environment',
  repoURL: 'https://github.com/aetherrootr/os-environment.git',
  apiServer: 'https://kubernetes.default.svc',
  destinationNamespaces: [
    'applications-and-services',
    'infrastructure',
    'cloudflare-tunnel',
  ],
  description: 'Namespaced workloads; Argo CD and cluster bootstrap are managed independently',
  notificationEmails: [
    'aether@aetherrootr.com',
  ],
}
