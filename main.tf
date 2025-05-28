



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  subnet_ids = module.vpc.public_subnets
  vpc_id     = module.vpc.vpc_id

  enable_irsa = true

  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Essential EKS Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }

    # EKS Pod Identity Agent - For improved IRSA (OPTIONAL but recommended)
    eks-pod-identity-agent = {
      most_recent = true
    }
  }


  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t2.small"]
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.public_subnets
    }
  }




  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}
