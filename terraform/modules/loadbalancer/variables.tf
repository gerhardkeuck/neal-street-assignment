variable "name_prefix" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "app_port" { type = number }
variable "health_path" { type = string }
variable "vpc_id" { type = string }
