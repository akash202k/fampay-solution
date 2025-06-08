terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0" # New provider for Karpenter
    }
  }

  # Your existing backend configuration
  backend "s3" {
    bucket       = "tf-fampay-demo"
    key          = "fampay/eks/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}