variable "aws_region" {
  description = "AWS region for the selected workspace web tier."
  type        = string
  default     = "eu-west-1"
}

variable "allowed_account_ids" {
  description = "Expected AWS account IDs for this workspace.."
  type        = list(string)
}

variable "allowed_workspaces" {
  description = "Terraform workspaces this root module is allowed to manage. Dev is implemented; prod is documented for promotion."
  type        = list(string)
  default     = ["dev", "prod"]
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

variable "vpc_cidr" {
  description = "CIDR for the selected workspace VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public ALB subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR for the private app subnet."
  type        = list(string)
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the Terraform CI roles, in owner/repo format."
  type        = string
  default     = "gerhardkeuck/neal-street-assigment"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in owner/repo format."
  }
}

variable "github_ci_workspaces" {
  description = "Workspaces/environments that need GitHub Actions Terraform roles. Defaults to allowed_workspaces."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for workspace in var.github_ci_workspaces : can(regex("^[A-Za-z0-9_-]+$", workspace))])
    error_message = "github_ci_workspaces values must contain only letters, numbers, underscores, or hyphens."
  }
}

variable "github_oidc_subjects" {
  description = "Optional per-workspace GitHub OIDC subject overrides. Defaults to repo:<github_repository>:environment:<workspace>."
  type        = map(string)
  default     = {}
}

variable "github_role_name_prefix" {
  description = "Prefix for GitHub Actions Terraform role names."
  type        = string
  default     = "github-actions"

  validation {
    condition     = can(regex("^[A-Za-z0-9+=,.@_-]+$", var.github_role_name_prefix))
    error_message = "github_role_name_prefix contains characters IAM role names do not allow."
  }
}

variable "terraform_state_bucket" {
  description = "S3 bucket containing Terraform state. Defaults to the account-regional state bucket name."
  type        = string
  default     = null
}

variable "terraform_state_key" {
  description = "Terraform backend state key used by the live root module."
  type        = string
  default     = "rewards/terraform.tfstate"
}

variable "terraform_workspace_key_prefix" {
  description = "Terraform S3 backend workspace_key_prefix used by the live root module."
  type        = string
  default     = "env"
}
