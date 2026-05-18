locals {
  environment = terraform.workspace
  name_prefix = "${var.service}-${local.environment}"

  github_oidc_sub          = coalesce(var.github_oidc_sub, "repo:${var.github_repository}:ref:refs/heads/*")
  github_actions_role_name = "${local.name_prefix}-github-actions"

  terraform_state_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${var.terraform_state_bucket}"
  terraform_state_object     = "${var.terraform_workspace_key_prefix}/${local.environment}/*"

  tags = {
    environment = local.environment
    service     = var.service
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    workspace   = terraform.workspace
  }
}
