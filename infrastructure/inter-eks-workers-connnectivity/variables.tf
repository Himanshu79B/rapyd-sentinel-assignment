variable "security_group_rules" {
  type = map(object({
    cidr_block                    = string
    eks_workers_security_group_id = string
  }))
}
