locals {
  environment = terraform.workspace
  name_prefix = "${var.service}-${local.environment}"

  secret_name_prefix       = "/${local.environment}/${var.service}/"
  github_actions_role_name = "${local.name_prefix}-github-actions"

  tags = {
    environment = local.environment
    service     = var.service
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    workspace   = terraform.workspace
  }
}
