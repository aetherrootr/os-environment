#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a prepared Kubernetes cluster; Argo CD adopts the workloads afterwards.
# Run only after these definitions have been merged into the tracked master branch.
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
bootstrap_timeout=${BOOTSTRAP_TIMEOUT:-300s}

for tool in kubectl tk jb helm; do
  command -v "$tool" >/dev/null || { echo "Required command is missing: $tool" >&2; exit 1; }
done

required_token_namespaces=(argocd applications-and-services infrastructure cert-manager cloudflare-tunnel kubernetes-dashboard)
# Access tokens must be provisioned manually; check them before applying resources.
for namespace in "${required_token_namespaces[@]}"; do
  if ! kubectl -n "$namespace" get secret bw-auth-token >/dev/null 2>&1; then
    echo "Missing bw-auth-token in namespace $namespace. Create it manually as described in kubernetes/secrets/README.md#initial-credentials." >&2
    exit 1
  fi
done

# Find the dependency project for an inline Environment and install its tools.
deploy() {
  local entry=$1
  local project
  project=$(dirname "$entry")
  while [[ ! -f "$project/jsonnetfile.json" ]]; do
    [[ "$project" != . ]] || { echo "No Jsonnet project for $entry" >&2; exit 1; }
    project=$(dirname "$project")
  done
  (
    cd "$project"
    jb install
    if [[ -f chartfile.yaml ]]; then tk tool charts vendor; fi
  )
  tk apply "$entry" --auto-approve=always
}

echo 'Initializing namespaces, node configuration, RBAC and static storage'
deploy kubernetes/namespace/all-namespaces.jsonnet
deploy kubernetes/node/proxmox/node-config.jsonnet
while IFS= read -r entry; do deploy "$entry"; done < <(
  find kubernetes/role-binding/service-account -path '*/accounts/*.jsonnet' -not -path '*/vendor/*' | sort
)
while IFS= read -r entry; do deploy "$entry"; done < <(
  find kubernetes/volume -name instances.jsonnet -not -path '*/vendor/*' | sort
)

echo 'Bootstrapping Bitwarden operator and the independent Argo CD credentials'
deploy kubernetes/app/bitwarden-secrets-manager/env/prod.jsonnet
kubectl wait --for=condition=Established crd/bitwardensecrets.k8s.bitwarden.com --timeout="$bootstrap_timeout"
kubectl -n bitwarden-secrets-manager rollout status \
  deployment/bw-sm-op-sm-operator-controller-manager --timeout="$bootstrap_timeout"
for secret in argocd-secret argocd-redis argocd-notifications-secret; do
  deploy "kubernetes/secrets/$secret/env/prod.jsonnet"
  kubectl -n argocd wait --for=create "secret/$secret" --timeout="$bootstrap_timeout"
done

echo 'Installing Argo CD and registering managed applications'
deploy kubernetes/app/argocd/env/prod.jsonnet
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout="$bootstrap_timeout"
kubectl -n argocd rollout status deployment/argocd-server --timeout="$bootstrap_timeout"
deploy kubernetes/app/argocd/apps/env/prod.jsonnet

echo 'Bootstrap resources are applied; Argo CD is reconciling workloads and secret mappings.'
kubectl -n argocd get applications
