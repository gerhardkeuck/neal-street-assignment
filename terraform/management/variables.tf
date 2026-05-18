variable "aws_region" {
  description = "AWS region for the selected workspace web tier."
  type        = string
  default     = "eu-west-1"
}

variable "allowed_account_ids" {
  description = "Expected AWS account IDs for this workspace.."
  type        = list(string)
}

variable "service" {
  description = "Service name."
  type        = string
  default     = "rewards"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "candidate"
}

variable "cost_center" {
  description = "Cost centre tag value."
  type        = string
  default     = "payments"
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the Terraform CI roles, in owner/repo format."
  type        = string
  default     = "gerhardkeuck/neal-street-assignment"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in owner/repo format."
  }
}

variable "github_oidc_sub" {
  description = "GitHub OIDC subject claim. Defaults to any subject in github_repository."
  type        = string
  default     = ""
}

variable "terraform_state_bucket" {
  description = "S3 bucket containing Terraform state."
  type        = string
  default     = "tfstate-neal-street-696715199782-eu-west-1-an"
}

variable "terraform_workspace_key_prefix" {
  description = "Terraform S3 backend workspace_key_prefix used by the live root module."
  type        = string
  default     = "env"
}
