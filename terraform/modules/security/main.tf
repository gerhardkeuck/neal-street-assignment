resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Private app hosts; no internet ingress"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-app-sg" }

  lifecycle {
    ignore_changes = [ingress]
  }
}

# NLB target_type=instance with preserve_client_ip=false: the source IP at the
# instance is the NLB ENI sitting inside the VPC CIDR (used for both client
# traffic and health checks), so a VPC-CIDR rule on app_port is sufficient.
resource "aws_security_group_rule" "app_from_nlb" {
  description       = "App port reachable from NLB ENIs in the VPC"
  type              = "ingress"
  security_group_id = aws_security_group.app.id

  from_port   = var.app_port
  to_port     = var.app_port
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
