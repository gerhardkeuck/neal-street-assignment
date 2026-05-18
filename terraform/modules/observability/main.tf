# App log group is kept for future use (e.g. CloudWatch agent), but the
# mandatory observability path for this env is metrics + alarms below.
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.name_prefix}/app"
  retention_in_days = 14

  tags = { Name = "${var.name_prefix}-app-logs" }
}

# SNS topic that alarms publish to. Email subscription is conditional so the
# module is usable in CI / ephemeral envs without an address.
resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-alarms"

  tags = { Name = "${var.name_prefix}-alarms" }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# "Is it up?" — NLB target group reports zero healthy hosts.
# Dimensions for NLB target health use LoadBalancer + TargetGroup suffixes.
resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts" {
  alarm_name          = "${var.name_prefix}-no-healthy-hosts"
  alarm_description   = "Fires when the rewards target group has zero healthy hosts behind the NLB."
  namespace           = "AWS/NetworkELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = var.nlb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.name_prefix}-no-healthy-hosts" }
}

# "Is it overloaded?" — sustained high CPU across the ASG.
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name_prefix}-high-cpu"
  alarm_description   = "Fires when ASG average CPU stays above 80% for 10 minutes."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 60
  evaluation_periods  = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = { Name = "${var.name_prefix}-high-cpu" }
}
