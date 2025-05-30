# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}

# Custom policy with all EBS permissions
resource "aws_iam_policy" "ebs_csi_driver_custom_policy" {
  name        = "${var.cluster_name}-ebs-csi-driver-custom-policy"
  description = "Custom policy for EBS CSI Driver with all required permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:AttachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshotAttribute",
          "ec2:ModifySnapshotAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_managed_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Attach custom policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_custom_policy" {
  policy_arn = aws_iam_policy.ebs_csi_driver_custom_policy.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# Annotate the existing service account created by the EKS addon
resource "kubernetes_annotations" "ebs_csi_controller_sa" {
  api_version = "v1"
  kind        = "ServiceAccount"
  
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
  
  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
  }

  depends_on = [module.eks]
}