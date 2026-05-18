locals {
  environment = terraform.workspace
  name_prefix = "${var.service}-${local.environment}"

  tags = {
    environment = local.environment
    service     = var.service
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    workspace   = terraform.workspace
  }
}

check "supported_workspace" {
  assert {
    condition     = contains(var.allowed_workspaces, local.environment)
    error_message = "Invalid workspace '${terraform.workspace}'. Must be one of: ${join(", ", var.allowed_workspaces)}."
  }
}
