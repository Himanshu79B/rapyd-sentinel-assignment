module "vpc" {
  source = "../lib/vpc"

  name       = "vpc-backend"
  cidr_block = "10.110.0.0/16"

  azs = {
    a = {
      private_subnet_cidr = "10.110.1.0/24"
      public_subnet_cidr  = "10.110.101.0/24"
    }
    b = {
      private_subnet_cidr = "10.110.2.0/24"
      public_subnet_cidr  = "10.110.201.0/24"
    }
  }

  enable_internet_gw = true
  enable_nat_gw      = true

  additional_subnet_tags = {
    public = {
      "kubernetes.io/cluster/eks-backend" = "shared"
      "kubernetes.io/role/elb"            = "1"
    }

    private = {
      "kubernetes.io/cluster/eks-backend" = "shared"
      "kubernetes.io/role/internal-elb"   = "1"
    }
  }
}

module "eks" {
  source = "../lib/eks"

  eks_version = "1.34"

  vpc = {
    id         = module.vpc.vpc_id
    cidr_block = module.vpc.cidr_block
  }

  cluster = {
    name       = "eks-backend"
    subnet_ids = module.vpc.private_subnet_ids
  }

  workers = {
    subnet_ids    = module.vpc.private_subnet_ids
    instance_type = "t4g.medium"
    capacity_type = "ON_DEMAND"
    scaling_config = {
      desired_size = 1
      max_size     = 2
      min_size     = 1
    }
  }

  alb_ingress_controller = true

  api_access_config = {
    public       = false
    access_cidrs = []
  }
}
