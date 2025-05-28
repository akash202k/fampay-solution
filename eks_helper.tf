

# Get current AWS caller identity
data "aws_caller_identity" "current" {
  provider = aws
}

# Create EKS Access Entry for cluster admin access
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }

  depends_on = [module.eks]
}

# Associate cluster admin policy
resource "aws_eks_access_policy_association" "cluster_admin_policy" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}