# Argo CD

This configuration installs Argo CD `v3.5.6` in the dedicated `argocd` namespace using the repository's Jsonnet libraries and Tanka inline environments. The deployment follows the upstream [non-HA installation](https://github.com/argoproj/argo-cd/blob/v3.5.6/manifests/install.yaml).

The web interface is available at `https://argocd.corp.aetherrootr.com` after deployment. NGINX terminates TLS and forwards HTTP traffic to `argocd-server:80`. The server's `server.insecure` setting disables its internal TLS; the external endpoint remains HTTPS.

## Deployment layout

Run commands in this README from the repository root.

| Layer | Tanka entry point | Resources and ownership |
| --- | --- | --- |
| Namespace | [`kubernetes/namespace/all-namespaces.jsonnet`](../../namespace/all-namespaces.jsonnet) | Manages all declared namespaces, including `argocd`. |
| RBAC | [`kubernetes/role-binding/service-account/argocd/accounts/argocd.jsonnet`](../../role-binding/service-account/argocd/accounts/argocd.jsonnet) | Independently manages ServiceAccounts, Roles, RoleBindings, ClusterRoles and ClusterRoleBindings. |
| Credentials | [`kubernetes/secrets/argocd-secret/env/prod.jsonnet`](../../secrets/argocd-secret/env/prod.jsonnet) | Creates a BitwardenSecret. The Bitwarden operator manages the resulting `argocd-secret` Kubernetes Secret. |
| Redis credentials | [`kubernetes/secrets/argocd-redis/env/prod.jsonnet`](../../secrets/argocd-redis/env/prod.jsonnet) | Maps the Redis password from Bitwarden to the `auth` key in `argocd-redis`. |
| Notification credentials | [`kubernetes/secrets/argocd-notifications-secret/env/prod.jsonnet`](../../secrets/argocd-notifications-secret/env/prod.jsonnet) | Maps the Fastmail SMTP app password from Bitwarden to `smtp-password` in `argocd-notifications-secret`. |
| Certificate | [`kubernetes/certificates/corp.aetherrootr.com/namespaces/argocd.jsonnet`](../../certificates/corp.aetherrootr.com/namespaces/argocd.jsonnet) | Creates `argocd-wildcard-certificate`. cert-manager manages the TLS Secret `argocd-wildcard-certificate-tls`. |
| Application | [`kubernetes/app/argocd/env/prod.jsonnet`](env/prod.jsonnet) | Includes the three CRDs, configuration, workloads, Services, NetworkPolicies and Ingress. RBAC and the core credentials are managed through the separate entries above. |
| Workload Applications | [`kubernetes/app/argocd/apps/env/prod.jsonnet`](apps/env/prod.jsonnet) | Independently registers the workload AppProject and Applications. Initially includes `subconverter-prod`. |

The application entry imports [base.libsonnet](base.libsonnet), which assembles these components:

| File | Component |
| --- | --- |
| [server.libsonnet](server.libsonnet) | API server, web UI, metrics Service and Ingress |
| [repo-server.libsonnet](repo-server.libsonnet) | Repository access and manifest generation |
| [plugins/tanka/base.libsonnet](plugins/tanka/base.libsonnet) | Tanka config-management plugin configuration, sidecar and volumes |
| [application-controller.libsonnet](application-controller.libsonnet) | StatefulSet that reconciles applications |
| [applicationset-controller.libsonnet](applicationset-controller.libsonnet) | Generates applications from ApplicationSets |
| [redis.libsonnet](redis.libsonnet) | Redis cache using the Bitwarden-managed `argocd-redis` Secret |
| [dex-server.libsonnet](dex-server.libsonnet) | Bundled Dex component |
| [notifications-controller.libsonnet](notifications-controller.libsonnet) | Notifications controller and metrics Service |
| [config.libsonnet](config.libsonnet) | Argo CD ConfigMaps |
| [notifications.libsonnet](notifications.libsonnet) | Fastmail SMTP service, email templates and triggers |
| [network-policy.libsonnet](network-policy.libsonnet) | NetworkPolicies based on the upstream installation |
| [crds.libsonnet](crds.libsonnet) | Imports the official Application, ApplicationSet and AppProject CRD YAML files |

CRDs, ClusterRoles and ClusterRoleBindings are cluster-scoped. Other resources use the `argocd` namespace. The application controller retains the upstream cluster-wide management permissions. These manifests use ephemeral cache and working directories; they do not request PVCs or an external database.

The CRD dependency is declared in [jsonnetfile.json](jsonnetfile.json) at `v3.5.6`. [jsonnetfile.lock.json](jsonnetfile.lock.json) pins its commit and checksum. The official YAML is vendored in the ignored `vendor/` directory and read locally during rendering.

## Install the Argo CD CLI

Install the CLI on the machine used to prepare password hashes and access Argo CD. The Linux download below pins `v3.5.6` to match this repository. See the [official CLI installation guide](https://argo-cd.readthedocs.io/en/stable/cli_installation/) for other installation options.

On Fedora, install the download dependencies:

```bash
sudo dnf install curl ca-certificates
```

On Debian, install the download dependencies:

```bash
sudo apt update
sudo apt install curl ca-certificates
```

Then run the following on either Fedora or Debian to install the x86-64 binary:

```bash
argocd_version=v3.5.6

argocd_tmp=$(mktemp)

curl -fL \
  "https://github.com/argoproj/argo-cd/releases/download/${argocd_version}/argocd-linux-amd64" \
  -o "$argocd_tmp" &&
  sudo install -m 0755 "$argocd_tmp" /usr/local/bin/argocd

rm -f "$argocd_tmp"
```

On macOS, install the CLI with Homebrew:

```bash
brew install argocd
```

Homebrew installs the version currently provided by its [argocd formula](https://formulae.brew.sh/formula/argocd).

## Email notifications

Configure project recipients through `notificationEmails` in [apps/projects/os-environment/project.libsonnet](apps/projects/os-environment/project.libsonnet). The shared project template adds [notification subscription annotations](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/subscriptions/) to the AppProject, applying subscriptions to all its Applications. The `os-environment` project subscribes `aether@aetherrootr.com` to all six triggers below; projects without recipients have no subscriptions. Override `notificationTriggers` in the project configuration to select fewer events. These manifests define no global subscriptions. The Bitwarden operator manages the notification Secret directly.

| Trigger | Email event |
| --- | --- |
| `on-sync-running` | Synchronization started |
| `on-sync-succeeded` | Synchronization completed successfully; workloads may still be progressing |
| `on-deployed` | Synchronization succeeded and Argo CD reports the application as synced and healthy |
| `on-sync-failed` | Synchronization failed or encountered an error |
| `on-health-degraded` | Application health is degraded |
| `on-sync-status-unknown` | Argo CD cannot determine the synchronization status |

Subscribe to each desired trigger using `notifications.argoproj.io/subscribe.<trigger>.email`. Synchronization lifecycle notifications use the operation start time for deduplication, so a new synchronization of the same commit can notify again. Subscribing to both `on-sync-succeeded` and `on-deployed` produces separate completion and health notifications, which may arrive close together.

## Password timestamp trade-off

`admin.passwordMtime` is intentionally absent from the Bitwarden mapping. Argo CD fills it in at startup when it is missing. A later Bitwarden synchronization can remove the generated field when rewriting Secret data.

This means changing the password hash does not guarantee immediate revocation of previously issued admin sessions. A restart can regenerate the timestamp and require users to log in again. This is an accepted trade-off for keeping credential management entirely in the existing Bitwarden workflow. Password and signing-key changes should be handled through that workflow; direct UI or CLI password changes can be overwritten by later synchronization.

## Manual deployment order

```bash
# Run these steps manually from the repository root after preparing
# the prerequisites and credentials.

# 1. Create namespaces. This shared entry includes all declared namespaces,
# including argocd.
tk apply kubernetes/namespace/all-namespaces.jsonnet

# 2. Create ServiceAccounts and permissions.
tk apply kubernetes/role-binding/service-account/argocd/accounts/argocd.jsonnet

# 3. Provision bw-auth-token in argocd through the existing Bitwarden workflow,
# then apply the credential mapping.
tk apply kubernetes/secrets/argocd-secret/env/prod.jsonnet
tk apply kubernetes/secrets/argocd-redis/env/prod.jsonnet
tk apply kubernetes/secrets/argocd-notifications-secret/env/prod.jsonnet

# 4. Issue the certificate using the existing ClusterIssuer and DNS credentials.
# The Ingress uses the argocd-wildcard-certificate-tls Secret.
tk apply kubernetes/certificates/corp.aetherrootr.com/namespaces/argocd.jsonnet

# 5. Apply the CRDs, configuration, workloads, Services, NetworkPolicies and Ingress.
# env/prod.jsonnet sets spec.applyStrategy=server for the large CRDs.
tk apply kubernetes/app/argocd/env/prod.jsonnet

# 6. Open https://argocd.corp.aetherrootr.com and sign in as admin using the
# plaintext password corresponding to the bcrypt hash stored in Bitwarden.
# This setup does not rely on argocd-initial-admin-secret.
# CLI access through the HTTP ingress backend uses gRPC-Web.
argocd login argocd.corp.aetherrootr.com --grpc-web

# Configure repository credentials, projects and applications separately.
# These installation manifests include Tanka rendering support but do not
# register applications or configure automatic synchronization.
```

## Upgrades

Update the Argo CD image in [base.libsonnet](base.libsonnet) and the CRD dependency version together. Refresh the dependency lock file and local vendor directory. Apply updated RBAC, then apply the Argo CD entry to update its CRDs and workloads.

References: [upstream installation](https://github.com/argoproj/argo-cd/blob/v3.5.6/manifests/install.yaml), [CRD source](https://github.com/argoproj/argo-cd/tree/v3.5.6/manifests/crds), [ingress configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/), and [Argo CD Secret fields](https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-secret-yaml/).
