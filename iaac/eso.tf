# Install External Secrets Operator via Helm
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart           = "external-secrets"
  namespace       = "eso"
  create_namespace = true
  version         = "0.17.0"
  
  set {
    name  = "installCRDs"
    value = "true"
  }
}

# IAM Policy for External Secrets Operator
resource "aws_iam_policy" "eso_policy" {
  name        = "ESO-SecretsManager-Policy"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for ESO Service Account
resource "aws_iam_role" "eso_role" {
  name = "ESO-ServiceAccount-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:eso:external-secrets"
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eso_policy_attachment" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_policy.arn
}

# Data source for existing EKS OIDC provider
data "aws_iam_openid_connect_provider" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

# Annotate the default service account created by ESO
resource "kubernetes_annotations" "eso_sa_annotations" {
  depends_on = [helm_release.external_secrets]
  
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "external-secrets"
    namespace = "eso"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.eso_role.arn
  }
}

# EKS Access Entry for ESO (if needed for cluster access)
resource "aws_eks_access_entry" "eso_access" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_role.eso_role.arn
  kubernetes_groups = ["system:authenticated"]
  type             = "STANDARD"
}