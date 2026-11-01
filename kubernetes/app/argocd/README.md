# Argo CD

Argo CD `v3.5.6` runs in the `argocd` namespace with Tanka support.
Web interface: <https://argocd.corp.aetherrootr.com>.
Run all commands below from the repository root.

## Initialization

For cluster setup, follow the [bootstrap steps](../../README.md#bootstrap-with-argo-cd).
Prepare access tokens manually as described in the [Secrets README](../../secrets/README.md#initial-credentials).
Argo CD installation and its credentials are maintained independently of automatic application deployment.

For an existing Argo CD installation, merge the configuration and lock files into
remote `master`, then update the plugin and initialize application registration:

```bash
(cd kubernetes/app/argocd && jb install)
tk apply kubernetes/app/argocd/env/prod.jsonnet
kubectl -n argocd rollout status deployment/argocd-repo-server
tk apply kubernetes/app/argocd/apps/env/prod.jsonnet
kubectl -n argocd get applications
```

## Access

Sign in to the web interface as `admin` using the configured admin password.
For CLI access, [install the Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/) and run:

```bash
argocd login argocd.corp.aetherrootr.com --grpc-web
```

## Maintain applications and Secrets

| Configuration | File |
| --- | --- |
| Applications | [apps/projects/os-environment/apps.libsonnet](apps/projects/os-environment/apps.libsonnet) |
| Secret mappings | [apps/projects/os-environment/secrets.libsonnet](apps/projects/os-environment/secrets.libsonnet) |
| Project permissions and notification recipients | [apps/projects/os-environment/project.libsonnet](apps/projects/os-environment/project.libsonnet) |

Add or update an application dictionary in the appropriate list:

```jsonnet
{
  appName: 'subconverter-prod',
  appPath: 'kubernetes/app/subconverter',
  destinationNamespace: 'applications-and-services',
},
```

The default entry is `env/prod.jsonnet`; set `environment` for other entry paths.
Merge changes into `master`. Argo CD automatically updates registrations and deploys
application changes. The Bitwarden operator updates the actual Kubernetes Secrets.

To check synchronization:

```bash
kubectl -n argocd get applications
```

Automatic pruning and self-healing are disabled. Removing a list entry does not
delete its Application or workloads; remove them explicitly when retiring an application.
Jitsi preserves its current chart-generated credentials; rotate them manually and
restart the affected workloads when needed.

## Notifications and credentials

Set `notificationEmails` in the project configuration to change recipients.
The current recipient is `aether@aetherrootr.com`. Override `notificationTriggers`
to select events; defaults are defined in [apps/project.libsonnet](apps/project.libsonnet).

Update admin, Redis and SMTP credentials in Bitwarden using the existing
[argocd-secret](../../secrets/argocd-secret/env/prod.jsonnet),
[argocd-redis](../../secrets/argocd-redis/env/prod.jsonnet) and
[argocd-notifications-secret](../../secrets/argocd-notifications-secret/env/prod.jsonnet)
mappings. Store the admin password as a bcrypt hash. Direct UI or CLI password
changes can be overwritten. Password changes
do not guarantee immediate revocation of existing sessions.

## Privilege Apps

The registration parent is explicitly listed under `privilegeApps` in
[apps/base.libsonnet](apps/base.libsonnet). It maintains Application and AppProject
registrations, including its own declarations.

Add a Privilege App only when necessary. Review its source, destination,
permissions and resource overlap before merging. Removing its registration does
not stop an existing Privilege App; disable or delete it explicitly.

## Upgrades and recovery

For upgrades, update the Argo CD image in [base.libsonnet](base.libsonnet) and the
CRD version in [jsonnetfile.json](jsonnetfile.json), refresh dependencies and commit
the lock file. Apply changed RBAC, then repeat the commands under Initialization.

If automatic registration fails, fix or revert the configuration and reapply
`kubernetes/app/argocd/apps/env/prod.jsonnet` manually.
