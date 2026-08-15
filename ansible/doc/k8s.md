# Kubernetes

---

## Overview
Currently my k8s is deployed on a proxmox cluster which consists of a master node and a slave node.

My machine is the Intel NUC 11 Performance Kit - NUC11PAHi5 (unfortunately it's discontinued).

It is very easy to build a cluster using ansible scripts, just deploy the k8s-master node first and then the k8s-slave node.

New clusters are pinned to Kubernetes v1.35.7, Calico v3.32.1,
ingress-nginx v1.15.1, and cert-manager v1.21.1.

## k8s master

Run the command to deploy k8s master node:

```
ansible-galaxy collection install kubernetes.core
ansible-playbook -i inventories/pve/ playbooks/k8s_master.yaml -u root --ask-become-pass
```

## k8s salve

Run the command to deploy k8s all slave node:

```
ansible-playbook -i inventories/pve/ playbooks/k8s_slave.yaml -u root --ask-become-pass
```

## local machine

Run the command to prepare local dev env:
```
bash ../run_ansible.sh
ansible-playbook -i "localhost," -i inventories/pve/ playbooks/fetch_k8s_config.yaml -u root --ask-become-pass -e "kube_config_dir=$HOME/.kube"
```

## haproxy
We use haproxy to proxy external traffic for kubernetes. The configuration command is as follows：
```
ansible-playbook -i inventories/pve/ playbooks/edge-router.yaml -u root --ask-become-pass
```
## Progressive kubeadm upgrade

The existing `k8s_master.yaml` and `k8s_slave.yaml` playbooks provision a new
cluster. They must not be used for an in-place upgrade because the master role
runs `kubeadm reset` and `kubeadm init`.

The upgrade playbooks below perform one explicitly pinned Kubernetes step at a
time. Each step runs preflight checks, creates an etcd and configuration backup,
upgrades required add-ons, upgrades the control plane, and upgrades one worker
at a time. Progression is determined from live cluster state rather than marker
files.

Run commands from the repository root. Passwords are requested interactively
and are not stored in inventory or variable files.

### Required preparation

1. Confirm a maintenance window. Draining `k8s-node-1` interrupts hardware-bound,
   hostPath, database, and other single-replica workloads.
2. Back up application data on the NFS servers and
   `/media/service_data/prometheus` independently of the etcd backup.
3. Preferably create Proxmox snapshots of all three Kubernetes VMs.
4. Install the pinned local Ansible version and required collections with
   `bash install_ansible.sh`. The installer supports apt, dnf, and Homebrew,
   installs system dependencies through sudo when needed, and places Ansible in
   a user-local virtual environment.
5. Connect once with `ssh aether@HOST` to verify and save each node's SSH host
   key. Host-key checking remains enabled during the upgrade.
6. Verify password SSH and sudo access to every host:

```bash
ansible \
  -i ansible/inventories/pve/host.yaml \
  kubernetes \
  -m ansible.builtin.ping \
  --ask-pass --ask-become-pass
```

### Execution order

Never skip or reorder these playbooks:

```text
k8s_upgrade_1_29_15.yaml
k8s_upgrade_1_30_14.yaml
k8s_upgrade_1_31_14.yaml
k8s_upgrade_1_32_13.yaml
k8s_upgrade_1_33_13.yaml
k8s_upgrade_1_34_10.yaml
k8s_upgrade_1_35_7.yaml
```

Run one step as follows:

```bash
ansible-playbook \
  -i ansible/inventories/pve/host.yaml \
  ansible/playbooks/k8s_upgrade_1_29_15.yaml \
  --ask-pass --ask-become-pass \
  -e k8s_upgrade_confirm=true \
  -e k8s_data_backup_confirmed=true \
  -e k8s_cert_rotation_policy_confirmed=true
```

The cert-manager rotation confirmation is required only for the first step.
Before setting it, review Certificates that omit
`spec.privateKey.rotationPolicy`; cert-manager v1.18 changes the default to
`Always`.

After reviewing the result, rerun the validation independently:

```bash
ansible-playbook \
  -i ansible/inventories/pve/host.yaml \
  ansible/playbooks/k8s_validate.yaml \
  --ask-pass --ask-become-pass \
  -e k8s_target_version=v1.29.15
```

Only then replace the upgrade playbook and validation version with the next
entry in the ordered list. The following upgrade reads the live API server and
node states and refuses to continue unless every component is on the expected
source version and the cluster health checks pass. The current stage also
accepts its target version so an interrupted upgrade can be safely rerun.

### Backups and failure behavior

Control-plane backups are stored under
`/var/backups/kubernetes-upgrade/vX.Y.Z` and fetched to the ignored local
directory `ansible/backups/`. Worker configuration is backed up before its
package repository is changed.

If a task fails after a node is drained, the playbook intentionally leaves that
node cordoned. Investigate and rerun the same version playbook; do not proceed
to the next minor and do not attempt a package-only Kubernetes downgrade.
Restoring an earlier minor requires the matching etcd snapshot, Kubernetes
configuration, package versions, and preferably the VM snapshots.

The final Kubernetes step does not replace kube-state-metrics because that
component is managed by Tanka/Helm in
`kubernetes/app/monitor/exporters/kube-state-metrics`. Upgrade it to an image
compatible with Kubernetes 1.35 separately after the cluster reaches v1.35.7.

### Shared health checks

The `k8s_common` role's `healthcheck` task group is shared by installation,
upgrade, and standalone validation. `k8s_slave.yaml` runs it after all workers
join the cluster. Run it without an exact version requirement at any time with:

```bash
ansible-playbook \
  -i ansible/inventories/pve/host.yaml \
  ansible/playbooks/k8s_healthcheck.yaml \
  --ask-pass --ask-become-pass
```

Without `k8s_expected_version`, it requires the API server and kubelets to use
the same major/minor version. Upgrade validation additionally passes the exact
target patch version.

### Shared Kubernetes roles

Installation and upgrade share the `k8s_common` role. Callers select an explicit
task group with `tasks_from`:

- `repository` and `packages` manage the Kubernetes apt repository, exact
  package versions, installed-version verification, and package holds.
- `addons` manages Calico, calicoctl, cert-manager, ingress-nginx, rollout waits,
  and the ingress NodePort configuration.
- `healthcheck` performs installation, upgrade, and standalone validation.

The `k8s` role still owns new-cluster bootstrap, `kubeadm init`, and node join.
The `k8s_upgrade` role still owns preflight gates, backups, drain/uncordon, and
`kubeadm upgrade`. These lifecycle operations are intentionally not merged.
