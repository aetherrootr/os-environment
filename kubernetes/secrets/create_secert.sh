#!/bin/bash
set -ex

# Usage message
usage() {
  echo "Usage: $0 --token <csrf_token> [--namespace <namespace>] [--name <secret_name>]"
  echo
  echo "Options:"
  echo "  --token       token value (required)"
  echo "  --namespace   Kubernetes namespace (default: kubernetes-dashboard)"
  echo "  --name        Secret name (default: kubernetes-dashboard-csrf)"
  echo "  --token-type  Type of token (default: csrf)"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN="$2"
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
    --token-type)
      TOKEN_TYPE="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done


# Validate input
if [ -z "$TOKEN" ]; then
  echo "Error: token is required. Use --token."
  usage
fi

if [ -z "$NAMESPACE" ]; then
  echo "Error: namespace is required. Use --namespace."
  usage
fi

if [ -z "$SECRET_NAME" ]; then
  echo "Error: secret name is required. Use --name."
  usage
fi

if [ -z "$TOKEN_TYPE" ]; then
  echo "Warning: token type is not specified. Defaulting to 'csrf'."
  TOKEN_TYPE="csrf"
fi


# Delete existing secret if it exists
echo "Deleting existing secret '$SECRET_NAME' in namespace '$NAMESPACE' (if it exists)..."
kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE" --ignore-not-found

# Create the new secret
echo "Creating secret '$SECRET_NAME' in namespace '$NAMESPACE'..."
kubectl create secret generic "$SECRET_NAME" \
  --from-literal="$TOKEN_TYPE"="$TOKEN" \
  -n "$NAMESPACE"

echo "✅ Secret '$SECRET_NAME' has been successfully created in namespace '$NAMESPACE'."
echo "Token type: $TOKEN_TYPE"
