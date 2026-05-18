# S3 bucket used by Ansible's amazon.aws.aws_ssm connection plugin to stage
# file transfers between the controller and EC2 instances over SSM.
# Objects are short-lived (deleted by the plugin after each task), so we
# lifecycle-expire any stragglers and keep the bucket private.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "ansible_ssm" {
  bucket        = "${local.name_prefix}-ansible-ssm-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket                  = aws_s3_bucket.ansible_ssm.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ansible_ssm" {
  bucket = aws_s3_bucket.ansible_ssm.id

  rule {
    id     = "expire-transfer-objects"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
