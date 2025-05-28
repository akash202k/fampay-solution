module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "fampay-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  #   private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}

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


resource "aws_ecrpublic_repository" "fampay_ecr" {

  repository_name = "fampay-demo" # Better name

  catalog_data {
    about_text    = "FamPay Demo Application"
    architectures = ["x86-64"] # FIXED: Match your t2.small nodes
    description   = "Demo application for FamPay EKS cluster"
    # logo_image_blob   = filebase64("image.png")  # Optional - comment out if no image
    operating_systems = ["Linux"]
    usage_text        = "Docker image for FamPay demo application"
  }

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}