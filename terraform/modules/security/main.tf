resource "aws_security_group" "nlb" {
  name        = "${var.name_prefix}-nlb-sg"
  description = "Public HTTP entrypoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet for assignment health endpoint"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-nlb-sg" }
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Private app hosts; no internet ingress"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from NLB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  egress {
    description = "HTTPS to AWS APIs (SSM, CloudWatch) via NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-app-sg" }
}

resource "aws_security_group_rule" "app_from_vpc" {
  description       = "App traffic from load balancer subnets"
  type              = "ingress"
  security_group_id = aws_security_group.app.id

  from_port   = var.app_port
  to_port     = var.app_port
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
