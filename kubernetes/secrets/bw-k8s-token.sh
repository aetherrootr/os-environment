#!/bin/bash

set -e

if [ -z "$BW_SESSION" ]; then
  echo "❌ BW_SESSION not set. Run: export BW_SESSION=\$(bw unlock --raw)"
  exit 1
fi

usage() {
  echo "Usage:"
  echo "  $0 store --namespace <namespace> --name <secret_name> --token <value>"
  echo "  $0 get   --namespace <namespace> --name <secret_name>"
  exit 1
}

ACTION="$1"
shift || usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --name)
      SECRET_NAME="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$NAMESPACE" || -z "$SECRET_NAME" ]]; then
  usage
fi

ITEM_NAME="kubernetes/${NAMESPACE}/${SECRET_NAME}"

if [[ "$ACTION" == "store" ]]; then
  if [[ -z "$TOKEN" ]]; then
    echo "❌ Missing --token"
    usage
  fi

  ITEM_ID=$(bw list items --search "$ITEM_NAME" --session "$BW_SESSION" | jq -r '.[0].id // empty')

  if [[ -n "$ITEM_ID" ]]; then
    echo "🔁 Updating existing note: $ITEM_NAME"
    bw edit item "$ITEM_ID" "$(bw get template item | \
      jq --arg name "$ITEM_NAME" --arg token "$TOKEN" '
        .type = 2
        | .secureNote.type = 0
        | .name = $name
        | .notes = $token
      ' | bw encode)" --session "$BW_SESSION" > /dev/null
  else
    echo "➕ Creating new note: $ITEM_NAME"
    bw create item "$(bw get template item | \
      jq --arg name "$ITEM_NAME" --arg token "$TOKEN" '
        .type = 2
        | .secureNote.type = 0
        | .name = $name
        | .notes = $token
      ' | bw encode)" --session "$BW_SESSION" > /dev/null
  fi

  echo "✅ Secret stored in Bitwarden."
elif [[ "$ACTION" == "get" ]]; then
  echo "🔍 Retrieving token for: $ITEM_NAME"
  TOKEN=$(bw list items --search "$ITEM_NAME" --session "$BW_SESSION" | jq -r '.[0].id' | \
    xargs -r -I{} bw get item {} --session "$BW_SESSION" | jq -r '.notes')

  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "❌ Token not found for $ITEM_NAME"
    exit 1
  fi

  echo "✅ Token: $TOKEN"
else
  usage
fi
