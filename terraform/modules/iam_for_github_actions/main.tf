data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_oidc_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:ref:refs/heads/beta",
        "repo:${var.github_repo}:ref:refs/heads/dev",
        "repo:${var.github_repo}:ref:refs/tags/*",
        # optionally allow other refs / envs as needed
      ]
    }
  }
}

resource "aws_iam_role" "gh_actions_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume.json
}

data "aws_iam_policy_document" "bedrock_and_s3_policy" {
  statement {
    sid    = "AllowS3PutForWebsite"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.website_bucket_name}/*"
    ]
  }

  statement {
    sid    = "AllowBedrockInvoke"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ]

    # either allow all models (wildcard) or restrict to specific ARNs
    resources = [
      "arn:aws:bedrock:*::foundation-model/*",
      "arn:aws:bedrock:*::inference-profile/*"
    ]
  }
}

resource "aws_iam_policy" "gh_actions_permissions" {
  name   = "${var.role_name}-permissions"
  policy = data.aws_iam_policy_document.bedrock_and_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_permissions" {
  role       = aws_iam_role.gh_actions_role.name
  policy_arn = aws_iam_policy.gh_actions_permissions.arn
}