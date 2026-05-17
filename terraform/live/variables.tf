variable "aws_region" {
  description = "AWS region for the selected workspace web tier."
  type        = string
  default     = "eu-west-1"
}

variable "allowed_account_ids" {
  description = "Expected AWS account IDs for this workspace. Set in the workspace tfvars to prevent accidental applies."
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
