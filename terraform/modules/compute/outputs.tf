output "asg_name" {
  description = "Auto Scaling Group name — used by observability alarms to scope CPU metrics."
  value       = aws_autoscaling_group.app.name
}
