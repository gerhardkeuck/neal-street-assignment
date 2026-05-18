variable "aws_region" {
  description = "AWS region for the selected workspace web tier."
  type        = string
  default     = "eu-west-1"
}

variable "allowed_account_ids" {
  description = "Expected AWS account IDs for this workspace. Set in the workspace tfvars to prevent accidental applies."
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

variable "vpc_cidr" {
  description = "CIDR for the selected workspace VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public NLB subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR for the private app subnet."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for app hosts."
  type        = string
  default     = "t4g.nano"
}

variable "desired_capacity" {
  description = "Number of identical app instances. Increase this to scale later."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum ASG size."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 3
}

# Must set both app port and health path in terraform to be able to configure LB and Security Groups.
variable "app_port" {
  description = "Port served by the Ansible-managed app/service on EC2."
  type        = number
  default     = 8080
}

variable "health_path" {
  description = "Public health endpoint path."
  type        = string
  default     = "/health"
}

variable "ansible_ssm_bucket_name" {
  description = "Optional S3 bucket used by Ansible's aws_ssm connection plugin for file transfer."
  type        = string
  default     = ""
}
