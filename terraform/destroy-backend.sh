#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGION=eu-west-1
BUCKET_NAME=tfstate-neal-street-${ACCOUNT_ID}-${REGION}-an

# S3 delete-objects is limited to 1000 objects per request.
echo "Emptying bucket: ${BUCKET_NAME}"
while :; do
  versions=$(aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --max-keys 1000 \
    --no-paginate \
    --query '(Versions || `[]`)[].{Key:Key,VersionId:VersionId}' \
    --output json)

  markers=$(aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --max-keys 1000 \
    --no-paginate \
    --query '(DeleteMarkers || `[]`)[].{Key:Key,VersionId:VersionId}' \
    --output json)

  [[ "$versions" == "[]" && "$markers" == "[]" ]] && break

  if [[ "$versions" != "[]" ]]; then
    echo "Deleting object versions..."
    aws s3api delete-objects \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --delete "{\"Objects\": $versions}" >/dev/null
  fi

  if [[ "$markers" != "[]" ]]; then
    echo "Deleting delete markers..."
    aws s3api delete-objects \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --delete "{\"Objects\": $markers}" >/dev/null
  fi
done


echo "Deleting bucket: ${BUCKET_NAME}"
aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
echo "Bucket ${BUCKET_NAME} has been destroyed"
