variable "name_prefix" { type = string }
variable "app_secret_parameter_name" { type = string }
variable "github_actions_role_name" { type = string }
variable "ansible_ssm_bucket_name" {
  type    = string
  default = ""
}
