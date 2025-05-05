#!/bin/bash

# Usage message
usage() {
  echo "Usage: $0 --token <csrf_token> [--namespace <namespace>] [--name <secret_name>]"
  echo
  echo "Options:"
  echo "  --token       CSRF token value (or set CSRF_TOKEN environment variable)"
  echo "  --namespace   Kubernetes namespace (default: kubernetes-dashboard)"
  echo "  --name        Secret name (default: kubernetes-dashboard-csrf)"
  exit 1
}

# Default values
NAMESPACE="kubernetes-dashboard"
SECRET_NAME="kubernetes-dashboard-csrf"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      CSRF_TOKEN="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --name)
      SECRET_NAME="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

# Fallback to environment variable
CSRF_TOKEN="${CSRF_TOKEN:-$CSRF_TOKEN}"

# Validate input
if [ -z "$CSRF_TOKEN" ]; then
  echo "Error: CSRF token is required. Use --token or set CSRF_TOKEN environment variable."
  usage
fi

# Delete existing secret if it exists
echo "Deleting existing secret '$SECRET_NAME' in namespace '$NAMESPACE' (if it exists)..."
kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found

# Create the new secret
echo "Creating secret '$SECRET_NAME' in namespace '$NAMESPACE'..."
kubectl create secret generic "$SECRET_NAME" \
  --from-literal=csrf="$CSRF_TOKEN" \
  -n "$NAMESPACE"

echo "✅ Secret '$SECRET_NAME' has been successfully created in namespace '$NAMESPACE'."
