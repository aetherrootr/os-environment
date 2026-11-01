local k8sUtils = import 'utils/k8s-utils.libsonnet';

{
  namespace:: error 'namespace is required',
  hostname:: k8sUtils.getServiceHostname('argocd'),
  emailUsername:: error 'emailUsername is required',
  emailFrom:: error 'emailFrom is required',

  notifications: [
    k8sUtils.generateConfigMap(
      namespace=$.namespace,
      appName='argocd-notifications-cm',
      data={
        context: std.manifestYamlDoc({ argocdUrl: 'https://' + $.hostname }),
        'service.email': std.manifestYamlDoc({
          host: 'smtp.fastmail.com',
          port: 465,
          username: $.emailUsername,
          from: $.emailFrom,
          password: '$smtp-password',
          html: false,
          insecure_skip_verify: false,
        }),
        'trigger.on-sync-failed': std.manifestYamlDoc([{
          description: 'Application synchronization failed.',
          when: "app.status.operationState != nil && app.status.operationState.phase in ['Error', 'Failed']",
          oncePer: 'app.status.operationState?.startedAt',
          send: ['app-sync-failed'],
        }]),
        'trigger.on-sync-running': std.manifestYamlDoc([{
          description: 'Application synchronization started.',
          when: "app.status.operationState != nil && app.status.operationState.phase == 'Running'",
          oncePer: 'app.status.operationState?.startedAt',
          send: ['app-sync-running'],
        }]),
        'trigger.on-sync-succeeded': std.manifestYamlDoc([{
          description: 'Application synchronization succeeded.',
          when: "app.status.operationState != nil && app.status.operationState.phase == 'Succeeded'",
          oncePer: 'app.status.operationState?.startedAt',
          send: ['app-sync-succeeded'],
        }]),
        'trigger.on-deployed': std.manifestYamlDoc([{
          description: 'Application is synced and healthy after a successful synchronization.',
          when: "app.status.operationState != nil && app.status.operationState.phase == 'Succeeded' && app.status.sync.status == 'Synced' && app.status.health.status == 'Healthy'",
          oncePer: 'app.status.operationState?.startedAt',
          send: ['app-deployed'],
        }]),
        'trigger.on-sync-status-unknown': std.manifestYamlDoc([{
          description: 'Application synchronization status is unknown.',
          when: "app.status.sync.status == 'Unknown'",
          send: ['app-sync-status-unknown'],
        }]),
        'trigger.on-health-degraded': std.manifestYamlDoc([{
          description: 'Application health is degraded.',
          when: "app.status.health.status == 'Degraded'",
          send: ['app-health-degraded'],
        }]),
        'template.app-sync-failed': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: sync failed' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Sync result: {{.app.status.operationState.phase}}
            Finished at: {{.app.status.operationState.finishedAt}}
            Error: {{.app.status.operationState.message}}
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}?operation=true
          |||,
        }),
        'template.app-sync-running': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: sync started' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Started at: {{.app.status.operationState.startedAt}}
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}?operation=true
          |||,
        }),
        'template.app-sync-succeeded': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: sync succeeded' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Started at: {{.app.status.operationState.startedAt}}
            Finished at: {{.app.status.operationState.finishedAt}}
            Health: {{.app.status.health.status}}
            Synchronization succeeded. Workloads may still be progressing; on-deployed reports when Argo CD considers the application synced and healthy.
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}?operation=true
          |||,
        }),
        'template.app-deployed': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: deployment healthy' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Sync: {{.app.status.sync.status}}
            Health: {{.app.status.health.status}}
            Sync finished at: {{.app.status.operationState.finishedAt}}
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}
          |||,
        }),
        'template.app-sync-status-unknown': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: sync status unknown' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Sync: {{.app.status.sync.status}}
            {{range .app.status.conditions}}
            {{.type}}: {{.message}}
            {{end}}
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}
          |||,
        }),
        'template.app-health-degraded': std.manifestYamlDoc({
          email: { subject: '[Argo CD] {{.app.metadata.name}}: health degraded' },
          message: |||
            Application: {{.app.metadata.name}}
            Namespace: {{.app.metadata.namespace}}
            Health: {{.app.status.health.status}}
            {{range .app.status.conditions}}
            {{.type}}: {{.message}}
            {{end}}
            Details: {{.context.argocdUrl}}/applications/{{.app.metadata.namespace}}/{{.app.metadata.name}}
          |||,
        }),
      },
      labels={
        'app.kubernetes.io/component': 'notifications-controller',
        'app.kubernetes.io/name': 'argocd-notifications-controller',
        'app.kubernetes.io/part-of': 'argocd',
      },
    ),
  ],
}
