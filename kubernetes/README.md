# Kubernetes

---

Based on [grafana tanka](https://github.com/grafana/tanka) management configuration.
[Document](https://tanka.dev/)

## Initialize the local environment
Install tanka cli and jb
for x86-64
```
sudo curl -Lo /usr/local/bin/tk https://github.com/grafana/tanka/releases/latest/download/tk-linux-amd64
sudo chmod a+x /usr/local/bin/tk

sudo curl -Lo /usr/local/bin/jb https://github.com/jsonnet-bundler/jsonnet-bundler/releases/latest/download/jb-linux-amd64
sudo chmod a+x /usr/local/bin/jb

# Configuration completion requires restarting the shell to take effect
tk complete
```

for Macos
```
brew install tanka

brew install jsonnet-bundler

# Configuration completion requires restarting the shell to take effect
tk complete
```


## Bootstrap with Argo CD

Start with a working Kubernetes cluster configured by [Ansible](../ansible/doc/k8s.md)
(including Calico, ingress-nginx and cert-manager), and local `kubectl`, `tk`, `jb`
and Helm commands. Review the node names in `node/proxmox/node-groups.libsonnet`,
NFS exports/data in `volume/`, and the existing Bitwarden secret IDs before starting.
Shared namespace certificates and the special Authentik certificate are maintained
separately through the existing `certificates/` entries.
Merge these definitions into remote `master` first: Argo CD reads that branch,
including the dependency lock files.

1. Create the namespaces from the repository root:

   ```bash
   (cd kubernetes/namespace && jb install)
   tk apply kubernetes/namespace/all-namespaces.jsonnet
   ```

   Follow the [Secrets README](secrets/README.md#initial-credentials) to manually
   create `bw-auth-token` in `argocd`, `applications-and-services`, `infrastructure`,
   `cert-manager`, `cloudflare-tunnel` and `kubernetes-dashboard`. This credential
   setup is manual; the bootstrap script does not create or update access tokens.
2. From the repository root, bootstrap the cluster:

   ```bash
   bash kubernetes/bootstrap.sh
   ```

3. Watch application synchronization:

   ```bash
   kubectl -n argocd get applications -w
   ```

The script checks that the manually provisioned access tokens exist before
applying resources. It applies namespaces, node configuration, RBAC and static
volumes; installs Bitwarden operator; waits for Argo CD credentials; then
installs Argo CD with its Tanka plugin and bootstraps the registration root. It applies
resources without interactive confirmation. Argo CD subsequently maintains the
workloads and business `BitwardenSecret` mappings from Git. Secret values remain
in Bitwarden and are synchronized by the operator. Workloads can initially wait
for their Secrets while the operator reconciles.

Namespaces, nodes, RBAC and volumes alone cannot start this chain: the operator,
access tokens and Argo CD installation are also required. Argo CD's own credentials
remain independently bootstrapped to avoid self-management. Certificate setup is
outside this script.
The root Application automatically maintains application/project registrations
from `master`, including changes to the application and Secret lists. Its own
Application and AppProject are initially created through
`kubernetes/app/argocd/apps/env/prod.jsonnet`, together with the workload
registrations. Automatic pruning is disabled;
removing an entry from Git does not delete its Application or stop its workloads.
