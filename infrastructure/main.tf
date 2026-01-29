module "backend" {
  source = "./backend"
}

module "gateway" {
  source = "./gateway"
}

module "vpc_peering" {
  source = "./lib/vpc_peering"

  transit_gw_name = "backend-gateway"

  vpcs = {
    backend = {
      vpc_id                  = module.backend.vpc.id
      cidr_block              = module.backend.vpc.cidr_block
      private_subnet_ids      = module.backend.vpc.private_subnet_ids
      private_route_table_ids = module.backend.vpc.private_route_table_ids
    }
    gateway = {
      vpc_id                  = module.gateway.vpc.id
      cidr_block              = module.gateway.vpc.cidr_block
      private_subnet_ids      = module.gateway.vpc.private_subnet_ids
      private_route_table_ids = module.gateway.vpc.private_route_table_ids
    }
  }
}

module "inter_eks_workers_connnectivity" {
  source = "./inter-eks-workers-connnectivity"

  security_group_rules = {
    backend_to_gateway = {
      cidr_block                    = module.backend.vpc.cidr_block
      eks_workers_security_group_id = module.gateway.eks_workers_security_group_id
    }
    gateway_to_backend = {
      cidr_block                    = module.gateway.vpc.cidr_block
      eks_workers_security_group_id = module.backend.eks_workers_security_group_id
    }
  }
}
