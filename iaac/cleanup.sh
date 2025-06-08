#!/bin/bash


# Delete existing NodePools first (they reference EC2NodeClasses)
kubectl delete nodepool demo-app-nodepool --ignore-not-found=true
kubectl delete nodepool default --ignore-not-found=true

# Delete existing EC2NodeClasses
kubectl delete ec2nodeclass demo-app-nodeclass --ignore-not-found=true
kubectl delete ec2nodeclass default --ignore-not-found=true

# Wait for resources to be fully deleted
echo "Waiting for resources to be deleted..."
while kubectl get nodepool demo-app-nodepool >/dev/null 2>&1; do
  echo "  Waiting for demo-app-nodepool deletion..."
  sleep 5
done

while kubectl get ec2nodeclass demo-app-nodeclass >/dev/null 2>&1; do
  echo "  Waiting for demo-app-nodeclass deletion..."
  sleep 5
done

while kubectl get ec2nodeclass default >/dev/null 2>&1; do
  echo "  Waiting for default nodeclass deletion..."
  sleep 5
done

echo "✅ All resources deleted successfully"

2. CHECK CURRENT ROLE NAME
-------------------------
Check what role name Terraform is trying to use:

terraform output karpenter_node_iam_role_name

3. ALTERNATIVE: USE EXISTING ROLE
================================
If you want to use the existing role, check what it was called:

# Check existing EC2NodeClass to see the role it was using
kubectl get ec2nodeclass demo-app-nodeclass -o yaml | grep role:

4. FORCE REPLACEMENT IN TERRAFORM
=================================
You can also force Terraform to replace the resources:

# Force replacement of the problematic resources
terraform apply -replace=kubectl_manifest.demo_app_nodeclass -replace=kubectl_manifest.karpenter_default_nodeclass

5. RECOMMENDED APPROACH
======================
Run the cleanup commands from step 1, then run:

terraform apply

This will recreate the resources with the correct role name.

🎯 QUICK CLEANUP COMMANDS:
=========================
Copy and paste these commands:

kubectl delete nodepool --all --wait=true
kubectl delete ec2nodeclass --all --wait=true