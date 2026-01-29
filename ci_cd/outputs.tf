output "github_actions_iam_role_arn" {
  value = {
    terraform = aws_iam_role.github_actions_terraform.arn
    eks       = aws_iam_role.github_actions_eks.arn
  }
}
