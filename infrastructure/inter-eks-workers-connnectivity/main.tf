resource "aws_security_group_rule" "inter_eks_workers_connnectivity" {
  for_each = var.security_group_rules

  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [each.value.cidr_block]
  security_group_id = each.value.eks_workers_security_group_id
}
