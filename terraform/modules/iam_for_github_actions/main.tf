data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:ref:refs/heads/feature/*",
        "repo:${var.github_repo}:ref:refs/heads/beta",
        "repo:${var.github_repo}:ref:refs/heads/dev",
        "repo:${var.github_repo}:ref:refs/tags/*",
        "repo:${var.github_repo}:environment:prod",
        "repo:${var.github_repo}:environment:dev",
        "repo:${var.github_repo}:environment:beta"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_policy" "this" {
  name = "${var.role_name}-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:CopyObject",
          "bedrock:InvokeModel",
          "bedrock:ListModels",
          "bedrock:DescribeModel",
          "bedrock:CreateModelCustomizationJob",
          "bedrock:DescribeModelCustomizationJob",
          "bedrock:ListModelCustomizationJobs"
        ],
        Resource = [
          "arn:aws:s3:::specific-bucket-name/*", # Replace with your specific bucket ARN
          "arn:aws:bedrock:region:account-id:model/*" # Replace with specific Bedrock model ARNs
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
