#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGION=eu-west-1
BUCKET_NAME=tfstate-neal-street-${ACCOUNT_ID}-${REGION}-an

# Page size 1000 as delete objects limited to that page size.
echo "Emptying bucket: ${BUCKET_NAME}"
while :; do
  payload=$(aws s3api list-object-versions \
    --bucket "${BUCKET_NAME}" \
    --max-items 1000 \
    --output json \
    --query '{Objects: (Versions || `[]`)[].{Key:Key,VersionId:VersionId}
                     + (DeleteMarkers || `[]`)[].{Key:Key,VersionId:VersionId}}')
  [[ "$(jq '.Objects | length' <<<"$payload")" -eq 0 ]] && break
  aws s3api delete-objects --bucket "${BUCKET_NAME}" --delete "$payload" >/dev/null
done

echo "Deleting bucket: ${BUCKET_NAME}"
aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
echo "Bucket ${BUCKET_NAME} has been destroyed"