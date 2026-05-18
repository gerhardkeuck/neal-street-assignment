variable "name_prefix" { type = string }

# Path prefix under which Secrets Manager secrets for this app live.
# Example: "/dev/rewards/" — the role gets read access to "<prefix>*".
variable "app_secret_name_prefix" { type = string }
variable "github_actions_role_name" { type = string }
variable "ansible_ssm_bucket_name" {
  type    = string
  default = ""
}
