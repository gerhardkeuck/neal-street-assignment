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
# Create an example secret for demonstration. In practice, this script and the secret content won't be commited in the repo.
SECRET_VALUE='{"APP_SECRET":"hello-from-secrets-manager"}'

if aws secretsmanager describe-secret \
     --secret-id "$SECRET_NAME" \
     --region "$REGION" >/dev/null 2>&1; then
  echo "Secret exists, updating: $SECRET_NAME"
  aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --secret-string "$SECRET_VALUE"
else
  echo "Creating secret: $SECRET_NAME"
  aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --region "$REGION" \
    --secret-string "$SECRET_VALUE"
fi

echo "Finished upserting secret."
