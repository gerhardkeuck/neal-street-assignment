output "github_actions_role_arns" {
  description = "GitHub Actions Terraform role ARNs by workspace."
  value = {
    for workspace, role in aws_iam_role.github_actions_terraform :
    workspace => role.arn
  }
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_state_objects" {
  description = "Terraform state objects each GitHub Actions role can access."
  value = {
    for workspace, state_object in local.terraform_state_objects :
    workspace => "s3://${local.terraform_state_bucket}/${state_object}"
  }
}
