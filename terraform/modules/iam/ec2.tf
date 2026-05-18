data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = { Name = "${var.name_prefix}-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "app_secret" {
  statement {
    sid    = "ReadAppSecretsByPrefix"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    # Secrets Manager appends a 6-char random suffix to the ARN; the trailing
    # "*" covers both that suffix and any sibling secret under the prefix.
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.app_secret_name_prefix}*"
    ]
  }
}

resource "aws_iam_policy" "app_secret" {
  name        = "${var.name_prefix}-app-secret-read"
  description = "Permit EC2 app role to read externally provisioned Secrets Manager secrets under the app prefix."
  policy      = data.aws_iam_policy_document.app_secret.json
}

resource "aws_iam_role_policy_attachment" "app_secret" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.app_secret.arn
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = { Name = "${var.name_prefix}-ec2-profile" }
}
