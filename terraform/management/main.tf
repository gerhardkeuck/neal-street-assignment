# TODO only create the role, sufficently to assume role and apply terraform in live. Further roles

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  github_ci_workspaces = length(var.github_ci_workspaces) == 0 ? var.allowed_workspaces : var.github_ci_workspaces
  github_oidc_subjects = {
    for workspace in local.github_ci_workspaces :
    workspace => lookup(
      var.github_oidc_subjects,
      workspace,
      "repo:${var.github_repository}:environment:${workspace}"
    )
  }

  terraform_state_bucket = "tfstate-neal-street-696715199782-eu-west-1-an"
  terraform_state_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.terraform_state_bucket}"

  terraform_state_objects = {
    for workspace in local.github_ci_workspaces :
    workspace => "${var.terraform_workspace_key_prefix}/${workspace}/${var.terraform_state_key}"
  }
  terraform_lock_objects = {
    for workspace, state_object in local.terraform_state_objects :
    workspace => "${state_object}.tflock"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    Name = "${var.service}-github-actions-oidc"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  for_each = toset(local.github_ci_workspaces)

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subjects[each.key]]
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  for_each = toset(local.github_ci_workspaces)

  name               = "${var.github_role_name_prefix}-${var.service}-${each.key}-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[each.key].json
  description        = "GitHub Actions Terraform role for ${var.service} ${each.key}."

  tags = merge(local.tags, {
    Name        = "${var.github_role_name_prefix}-${var.service}-${each.key}-terraform"
    environment = each.key
    workspace   = each.key
  })

  lifecycle {
    precondition {
      condition     = length("${var.github_role_name_prefix}-${var.service}-${each.key}-terraform") <= 64
      error_message = "GitHub Actions role name for workspace '${each.key}' exceeds the IAM role name limit of 64 characters."
    }
  }
}

data "aws_iam_policy_document" "github_actions_state_access" {
  for_each = toset(local.github_ci_workspaces)

  statement {
    sid       = "ReadBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.terraform_state_bucket_arn]
  }

  statement {
    sid       = "ListWorkspaceState"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.terraform_state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        var.terraform_state_key,
        var.terraform_workspace_key_prefix,
        "${var.terraform_workspace_key_prefix}/",
        "${var.terraform_workspace_key_prefix}/${each.key}",
        "${var.terraform_workspace_key_prefix}/${each.key}/*",
      ]
    }
  }

  statement {
    sid    = "ReadWriteWorkspaceState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${local.terraform_state_bucket_arn}/${local.terraform_state_objects[each.key]}",
      "${local.terraform_state_bucket_arn}/${local.terraform_lock_objects[each.key]}",
    ]
  }

  statement {
    sid       = "DeleteWorkspaceLockFile"
    effect    = "Allow"
    actions   = ["s3:DeleteObject"]
    resources = ["${local.terraform_state_bucket_arn}/${local.terraform_lock_objects[each.key]}"]
  }
}

resource "aws_iam_role_policy" "github_actions_state_access" {
  for_each = toset(local.github_ci_workspaces)

  name   = "${aws_iam_role.github_actions_terraform[each.key].name}-state"
  role   = aws_iam_role.github_actions_terraform[each.key].id
  policy = data.aws_iam_policy_document.github_actions_state_access[each.key].json
}
