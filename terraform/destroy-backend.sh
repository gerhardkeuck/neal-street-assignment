#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGION=eu-west-1
# Create the bucket namespaced to the account and region
# Must follow the format bucket-name-prefix-accountId-region-an for account-regional buckets
BUCKET_NAME=tfstate-neal-street-${ACCOUNT_ID}-${REGION}-an

echo "Removing all objects and versions from bucket: ${BUCKET_NAME}"
aws s3api delete-objects \
  --bucket "${BUCKET_NAME}" \
  --delete "$(aws s3api list-object-versions \
    --bucket "${BUCKET_NAME}" \
    --output json \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" \
  2>/dev/null || echo "No versions to delete"

aws s3api delete-objects \
  --bucket "${BUCKET_NAME}" \
  --delete "$(aws s3api list-object-versions \
    --bucket "${BUCKET_NAME}" \
    --output json \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" \
  2>/dev/null || echo "No delete markers to remove"

echo "Deleting bucket: ${BUCKET_NAME}"
aws s3api delete-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}"

echo "Bucket ${BUCKET_NAME} has been destroyed"



