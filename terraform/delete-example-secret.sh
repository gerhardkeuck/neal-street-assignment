#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <env>" >&2
  echo "Example: $0 dev" >&2
  exit 1
fi

ENV="$1"
REGION=eu-west-1
SECRET_NAME="/${ENV}/rewards/config"

aws secretsmanager delete-secret \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --force-delete-without-recovery

echo "Finished deleting secret."
