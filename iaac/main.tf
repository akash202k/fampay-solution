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
    # On-Demand node group (for critical workloads)
    on_demand = {
      name           = "on-demand-nodes"
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3.small"]  # Slightly better than t2.small
      capacity_type  = "ON_DEMAND"
      subnet_ids     = module.vpc.public_subnets
      
      labels = {
        node-type = "on-demand"
      }
      
      # taints = [
      #   {
      #     key    = "node-type"
      #     value  = "on-demand"
      #     effect = "NO_SCHEDULE"
      #   }
      # ]
    }
    
    # Spot instance node group (for cost savings)
    spot = {
      name           = "spot-nodes"
      desired_size   = 2
      max_size       = 2
      min_size       = 1
      
      # Mix of instance types for better spot availability
      instance_types = ["t3.small","t2.small", "t2.medium"]
      capacity_type  = "SPOT"
      subnet_ids     = module.vpc.public_subnets
      
      # Spot-specific configuration
      spot_allocation_strategy = "diversified"
      
      labels = {
        node-type = "spot"
        lifecycle = "spot"
      }
      
      # taints = [
      #   {
      #     key    = "node-type"
      #     value  = "spot"
      #     effect = "NO_SCHEDULE"
      #   }
      # ]
      
      # User data to handle spot interruptions gracefully
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        # Install AWS Node Termination Handler
        curl -o aws-node-termination-handler.yaml https://github.com/aws/aws-node-termination-handler/releases/download/v1.19.0/all-resources.yaml
      EOT
    }
  }

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}