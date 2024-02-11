# Kubernetes

---

## Overview
Currently my k8s is deployed on a proxmox cluster which consists of a master node and a slave node.

My machine is the Intel NUC 11 Performance Kit - NUC11PAHi5 (unfortunately it's discontinued).

It is very easy to build a cluster using ansible scripts, just deploy the k8s-master node first and then the k8s-slave node.

## k8s master

Run the command to deploy k8s master node:

```
ansible-playbook -i inventories/pve/ playbooks/k8s_master.yaml -u root --ask-become-pass
```

## k8s salve

Run the command to deploy k8s all slave node:

```
ansible-playbook -i inventories/pve/ playbooks/k8s_master.yaml -u root --ask-become-pass
```
