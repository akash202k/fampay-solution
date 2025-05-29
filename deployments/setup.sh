#!/bin/bash

# set -e

export AWS_PROFILE=fampay
echo "Using fampay aws profile"

# Step 1: Create argocd namespace (if not exists)
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Update kubebeconfig 
aws eks update-kubeconfig --region us-east-1 --name fampay-eks-cluster --profile fampay

# Step 2: Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD pods to be ready..."
kubectl rollout status deployment/argocd-server -n argocd

# Step 4: Apply local install.yaml (optional if just creating namespace again)
kubectl apply -f argocd/install.yaml

# Step 5: Apply the App of Apps
kubectl apply -f argocd/app-of-apps.yaml

echo "✅ ArgoCD and App of Apps setup complete."
