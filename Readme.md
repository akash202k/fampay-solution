# 🚀 Cloud Infrastructure & Application Deployment

Complete DevOps pipeline with infrastructure as code, automated deployments, and comprehensive observability for scalable microservices.

---

## 🛠️ Prerequisites

- **AWS CLI** configured with `~/.aws/credentials`
- **Terraform** installed
- Required **IAM permissions** for infrastructure provisioning

---

## ⚡ Quick Start

### Infrastructure Setup
```bash
cd iaac/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Application Deployment
```bash
cd deployments/
chmod +x setup.sh && bash setup.sh
```

---

## 🎯 What's Included

### **Core Features**
- **Dockerized Services** - Bran and Hodr microservices
- **Auto Scaling** - HPA for applications, ASG for nodes
- **Secrets Management** - External Secrets Operator + AWS Secrets Manager
- **Network Security** - Kubernetes Network Policies
- **Single Entry Point** - Ingress with path-based routing
- **One-Click Deploy** - Terraform + GitHub Actions

### **Observability Stack**
- **Metrics** - Prometheus + Grafana
- **Logging** - OpenSearch + Fluent Bit
- **Live Dashboards** - All tools accessible via web URLs

---

## 🏗️ Architecture

![Architecture Diagram](fampay_architecture.png)

**AWS EKS** cluster with auto-scaling nodes, load balancer, secure secrets management, and full observability stack.

---

## 📚 Repositories

- **Bran**: [github.com/akash202k/bran](https://github.com/akash202k/bran)
- **Hodr**: [github.com/akash202k/hodr](https://github.com/akash202k/hodr)

---

## 📁 Project Structure

```
├── iaac/           # Terraform infrastructure
├── deployments/    # Deployment scripts
└── README.md      # This file
```