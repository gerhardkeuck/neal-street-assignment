output "ansible_ssm_bucket_name" {
  description = "S3 bucket Ansible's aws_ssm connection plugin uses for file transfer. Export as ANSIBLE_SSM_BUCKET."
  value       = aws_s3_bucket.ansible_ssm.id
}
