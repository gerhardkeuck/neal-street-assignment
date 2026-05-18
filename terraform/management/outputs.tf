output "github_actions_role_arn" {
  description = "GitHub Actions role ARN for this workspace."
  value       = aws_iam_role.github_actions_terraform.arn
}
