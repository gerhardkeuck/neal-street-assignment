#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGION=eu-west-1
# Create the bucket namespaced to the account and region
# Must follow the format bucket-name-prefix-accountId-region-an for account-regional buckets
BUCKET_NAME=tfstate-neal-street-${ACCOUNT_ID}-${REGION}-an

if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "State bucket already exists: ${BUCKET_NAME}"
else
  echo "Creating state bucket: ${BUCKET_NAME}"
  create_bucket_output="$(
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --bucket-namespace account-regional \
      --region "${REGION}" \
      --create-bucket-configuration "LocationConstraint=${REGION}" 2>&1
  )" || {
    if [[ "${create_bucket_output}" == *BucketAlreadyOwnedByYou* ]]; then
      echo "State bucket already exists: ${BUCKET_NAME}"
    else
      printf '%s\n' "${create_bucket_output}" >&2
      exit 1
    fi
  }
fi

aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

aws s3api put-bucket-ownership-controls \
  --bucket "${BUCKET_NAME}" \
  --ownership-controls '{
    "Rules": [
      {
        "ObjectOwnership": "BucketOwnerEnforced"
      }
    ]
  }'

aws s3api put-bucket-policy \
  --bucket "${BUCKET_NAME}" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Sid\": \"DenyInsecureTransport\",
        \"Effect\": \"Deny\",
        \"Principal\": \"*\",
        \"Action\": \"s3:*\",
        \"Resource\": [
          \"arn:aws:s3:::${BUCKET_NAME}\",
          \"arn:aws:s3:::${BUCKET_NAME}/*\"
        ],
        \"Condition\": {
          \"Bool\": {
            \"aws:SecureTransport\": \"false\"
          }
        }
      }
    ]
  }"

echo "Finished creating the terraform state bucket."