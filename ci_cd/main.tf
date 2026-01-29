resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://${local.github_identity_provider_url}"
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    Name = local.name
  }
}

# Terraform
resource "aws_iam_role" "github_actions_terraform" {
  name = "${local.name}-terraform"

  assume_role_policy = local.assume_role_policy

  tags = {
    Name = "${local.name}-terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# EKS
resource "aws_iam_role" "github_actions_eks" {
  name = "${local.name}-eks"

  assume_role_policy = local.assume_role_policy

  tags = {
    Name = "${local.name}-eks"
  }
}

resource "aws_iam_role_policy" "github_actions_eks" {
  name = "eks-deploy"
  role = aws_iam_role.github_actions_eks.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ],
        "Resource" : "*"
      }
    ]
  })
}
