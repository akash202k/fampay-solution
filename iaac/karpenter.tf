# ============================================================================
# SIMPLIFIED KARPENTER INFRASTRUCTURE - SKIP CRD INSTALLATION
# This version assumes CRDs already exist and skips CRD management
# ============================================================================

# 1. ENSURE KARPENTER NAMESPACE EXISTS
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"

    labels = {
      "app.kubernetes.io/name"       = "karpenter"
      "app.kubernetes.io/managed-by" = "terraform"
      Environment                    = "fampay"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# 2. KARPENTER MODULE WITH CORRECT VARIABLES
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  # IRSA Configuration
  enable_irsa                = true
  irsa_oidc_provider_arn     = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # IAM Role Configuration
  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-karpenter-controller"
  iam_role_use_name_prefix = false

  # Additional policies for Karpenter nodes (EC2 instances)
  node_iam_role_additional_policies = {
    # Core EKS permissions
    AmazonEKSWorkerNodePolicy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    
    # Container registry access
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    
    # Systems Manager for debugging/maintenance
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    
    # EBS CSI permissions for volume management
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  # Node IAM Role Configuration
  create_node_iam_role = true
  node_iam_role_name = "${var.cluster_name}-karpenter-node"
  node_iam_role_use_name_prefix = false

  # SQS Queue for spot interruption
  enable_spot_termination = true
  queue_name = "${var.cluster_name}-karpenter"

  # Tags for resource discovery and management
  tags = {
    Environment = "fampay"
    Terraform   = "true"

    # CRITICAL: This tag enables Karpenter to discover resources
    "karpenter.sh/discovery" = var.cluster_name
  }

  depends_on = [kubernetes_namespace.karpenter]
}

# 3. INSTALL KARPENTER CONTROLLER ONLY (Skip CRDs)
resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.7"

  # Skip CRD installation - assume they exist
  skip_crds       = true
  force_update    = true
  cleanup_on_fail = true

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  values = [
    <<-EOT
    # Karpenter settings
    settings:
      clusterName: ${module.eks.cluster_name}
      interruptionQueue: ${module.karpenter.queue_name}
      featureGates:
        drift: true
        spotToSpotConsolidation: true
    
    # Service account (uses IRSA)
    serviceAccount:
      create: true
      name: karpenter
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    
    # Controller configuration
    controller:
      resources:
        requests:
          cpu: 1
          memory: 1Gi
        limits:
          cpu: 1
          memory: 1Gi
    
    # Webhook configuration
    webhook:
      enabled: true
      port: 8443
    
    # Tolerations for control plane nodes
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/control-plane
        operator: Exists
    
    # Affinity to prefer system nodes
    affinity:
      nodeAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 10
            preference:
              matchExpressions:
                - key: node-role.kubernetes.io/control-plane
                  operator: Exists
          - weight: 1
            preference:
              matchExpressions:
                - key: node-type
                  operator: In
                  values: ["on-demand"]
    
    # Pod Disruption Budget
    podDisruptionBudget:
      name: karpenter
      maxUnavailable: 1
    EOT
  ]

  depends_on = [
    module.karpenter,
    kubernetes_namespace.karpenter
  ]
}

# 4. TAG EXISTING VPC SUBNETS for Karpenter discovery
data "aws_subnets" "karpenter_subnets" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

resource "aws_ec2_tag" "karpenter_subnet_discovery" {
  for_each = toset(data.aws_subnets.karpenter_subnets.ids)

  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "karpenter_subnet_environment" {
  for_each = toset(data.aws_subnets.karpenter_subnets.ids)

  resource_id = each.value
  key         = "Environment"
  value       = "fampay"
}

# 5. TAG EKS SECURITY GROUPS for Karpenter discovery
data "aws_security_groups" "eks_cluster_security_groups" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["owned", "shared"]
  }
}

resource "aws_ec2_tag" "karpenter_sg_discovery" {
  for_each = toset(data.aws_security_groups.eks_cluster_security_groups.ids)

  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "karpenter_sg_environment" {
  for_each = toset(data.aws_security_groups.eks_cluster_security_groups.ids)

  resource_id = each.value
  key         = "Environment"
  value       = "fampay"
}

# 6. WAIT FOR KARPENTER CONTROLLER TO BE READY
resource "time_sleep" "wait_for_karpenter_controller" {
  depends_on = [helm_release.karpenter]

  create_duration = "60s"
}

# 7. CREATE DEFAULT NODEPOOL AND NODECLASS for testing (v1 API)
resource "kubectl_manifest" "karpenter_default_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      amiSelectorTerms:
        - alias: al2@latest
      role: ${module.karpenter.node_iam_role_name}
      
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}"
      
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}"
      
      instanceStorePolicy: RAID0
      
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 20Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
            iops: 3000
            throughput: 125
      
      tags:
        Environment: fampay
        ManagedBy: karpenter
        "karpenter.sh/discovery": "${var.cluster_name}"
  YAML

  depends_on = [
    time_sleep.wait_for_karpenter_controller,
    aws_ec2_tag.karpenter_subnet_discovery,
    aws_ec2_tag.karpenter_sg_discovery
  ]
}

resource "kubectl_manifest" "karpenter_default_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ["t3.medium", "t3.large", "t3.xlarge"]
          
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
            
          taints:
            - key: karpenter.sh/default
              value: "true"
              effect: NoSchedule
      
      limits:
        cpu: 1000
        memory: 1000Gi
      
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
        expireAfter: 30m
  YAML

  depends_on = [
    kubectl_manifest.karpenter_default_nodeclass
  ]
}

# 8. CREATE YOUR DEMO-APP NODECLASS AND NODEPOOL (v1 API)
resource "kubectl_manifest" "demo_app_nodeclass" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: demo-app-nodeclass
    spec:
      amiFamily: AL2
      amiSelectorTerms:
        - alias: al2@latest
      role: ${module.karpenter.node_iam_role_name}
      
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}"
      
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${var.cluster_name}"
      
      instanceStorePolicy: RAID0
      
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 20Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
            iops: 3000
            throughput: 125
      
      tags:
        Environment: fampay
        ManagedBy: karpenter
        NodePool: demo-app
        "karpenter.sh/discovery": "${var.cluster_name}"
  YAML

  depends_on = [
    time_sleep.wait_for_karpenter_controller,
    aws_ec2_tag.karpenter_subnet_discovery,
    aws_ec2_tag.karpenter_sg_discovery
  ]
}

resource "kubectl_manifest" "demo_app_nodepool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: demo-app-nodepool
    spec:
      template:
        spec:
          requirements:
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values: ["t3.small", "t3.medium", "t3.large"]
            - key: "topology.kubernetes.io/zone"
              operator: In
              values: ["us-east-1a", "us-east-1b"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "kubernetes.io/os"
              operator: In
              values: ["linux"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
          
          taints:
            - key: app
              value: demo-app
              effect: NoSchedule
          
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: demo-app-nodeclass
          
          expireAfter: 720h
            
      limits:
        cpu: "100"
        memory: "100Gi"
        
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 60s
        
        budgets:
        - nodes: "10%"
  YAML

  depends_on = [
    kubectl_manifest.demo_app_nodeclass
  ]
}

# 9. ADDITIONAL IAM PERMISSIONS for enhanced Karpenter functionality
resource "aws_iam_policy" "karpenter_additional_permissions" {
  name        = "${var.cluster_name}-karpenter-additional-policy"
  description = "Additional permissions for Karpenter enhanced functionality"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "pricing:GetProducts",
          "ec2:CreateFleet",
          "ec2:DescribeFleets",
          "ec2:ModifyFleet",
          "ec2:DeleteFleets",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:GetSpotPlacementScores",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:ModifyLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeNetworkInterfaceAttribute",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_additional_permissions" {
  policy_arn = aws_iam_policy.karpenter_additional_permissions.arn
  role       = module.karpenter.iam_role_name
}

# 10. OUTPUTS
output "karpenter_controller_iam_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = module.karpenter.iam_role_arn
}

output "karpenter_controller_iam_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = module.karpenter.iam_role_name
}

output "karpenter_node_iam_role_arn" {
  description = "ARN of the Karpenter node IAM role"
  value       = module.karpenter.node_iam_role_arn
}

output "karpenter_node_iam_role_name" {
  description = "Name of the Karpenter node IAM role"
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_instance_profile_name" {
  description = "Name of the instance profile for Karpenter nodes"
  value       = module.karpenter.instance_profile_name
}

output "karpenter_queue_name" {
  description = "Name of the SQS queue for Karpenter interruption handling"
  value       = module.karpenter.queue_name
}

output "karpenter_queue_arn" {
  description = "ARN of the SQS queue for Karpenter interruption handling"
  value       = module.karpenter.queue_arn
}

output "karpenter_namespace" {
  description = "Karpenter namespace name"
  value       = kubernetes_namespace.karpenter.metadata[0].name
}