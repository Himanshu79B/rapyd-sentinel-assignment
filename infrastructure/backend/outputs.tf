output "vpc" {
  value = {
    id                      = module.vpc.vpc_id
    cidr_block              = module.vpc.cidr_block
    private_subnet_ids      = module.vpc.private_subnet_ids
    private_route_table_ids = module.vpc.private_route_table_ids
  }
}

output "eks_workers_security_group_id" {
  value = module.eks.eks_workers_security_group_id
}
