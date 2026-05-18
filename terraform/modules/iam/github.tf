data "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid    = "DiscoverEc2Inventory"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "RunAnsibleOverSsm"
    effect = "Allow"
    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:GetConnectionStatus",
      "ssm:ResumeSession",
      "ssm:StartSession",
      "ssm:TerminateSession",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.ansible_ssm_bucket_name == "" ? [] : [var.ansible_ssm_bucket_name]

    content {
      sid       = "ListAnsibleSsmTransferBucket"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${statement.value}"]
    }
  }

  dynamic "statement" {
    for_each = var.ansible_ssm_bucket_name == "" ? [] : [var.ansible_ssm_bucket_name]

    content {
      sid    = "UseAnsibleSsmTransferObjects"
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
      ]
      resources = ["arn:aws:s3:::${statement.value}/*"]
    }
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.name_prefix}-github-actions-deploy"
  role   = data.aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}
