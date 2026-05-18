variable "name_prefix" {
  description = "Resource name prefix, e.g. rewards-dev."
  type        = string
}

variable "nlb_arn_suffix" {
  description = "NLB ARN suffix — dimension for AWS/NetworkELB metrics."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix — dimension for AWS/NetworkELB metrics."
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name — dimension for AWS/EC2 CPU metric."
  type        = string
}

variable "alarm_email" {
  description = "Optional email address to subscribe to alarm notifications. Empty = no subscription."
  type        = string
  default     = ""
}
