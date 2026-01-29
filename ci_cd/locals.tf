locals {
  name = "sentinel-github-actions"

  github_identity_provider_url = "token.actions.githubusercontent.com"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Federated = aws_iam_openid_connect_provider.github_actions.arn
          },
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${local.github_identity_provider_url}:aud" : "sts.amazonaws.com"
            },
            StringLike = {
              "${local.github_identity_provider_url}:sub" : "repo:himanshu79b/rapyd-sentinel:ref:refs/heads/main"
            }
          }
        }
      ]
  })

  default_tags = {
    project    = "rapyd-sentinel"
    created_by = "himanshu-bhimwal"
    task       = "devops-assignment-terraform"
  }
}
