# 🚀 Cloud Infrastructure & Application Deployment

This project provides a complete cloud infrastructure setup using Terraform and automated application deployment for scalable microservices architecture.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Core Objectives](#core-objectives)
- [Bonus Features](#bonus-features)
- [Architecture](#architecture)
- [Application Repositories](#application-repositories)

---

## 🌟 Overview

This project demonstrates a complete DevOps pipeline with infrastructure as code, automated deployments, monitoring, logging, and security best practices. The solution includes two microservices (Bran and Hodr) deployed on a scalable Kubernetes cluster with comprehensive observability.

---

## 📌 Prerequisites

Before getting started, ensure you have the following tools installed and configured:

- **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - Configure credentials in `~/.aws/credentials`
- **Terraform** - [Download](https://www.terraform.io/downloads.html)
- **Required IAM Permissions** for infrastructure provisioning
- **Shell Script Execution** permissions

---

## 🚀 Quick Start

### Step 1: Infrastructure Deployment

Set up your AWS credentials in `~/.aws/credentials`, then run:

```bash
cd iaac/
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Application Deployment

```bash
cd deployments/
chmod +x setup.sh
bash setup.sh
```

---

## 📁 Project Structure

```
├── iaac/                    # Infrastructure as Code (Terraform)
├── deployments/             # Application deployment scripts
│   └── setup.sh            # Main deployment script
├── fampay_architecture.png  # Architecture diagram
└── README.md               # This file
```

---

## 🎯 Core Objectives

### Infrastructure & Deployment Features

| **Objective** | **Implementation** | **Status** |
|---------------|-------------------|------------|
| **Docker Containerization** | Created Docker images for Bran and Hodr services | ✅ Complete |
| **Application Auto Scaling** | Implemented Horizontal Pod Autoscaler (HPA) | ✅ Complete |
| **Node Scaling** | Configured AWS Auto Scaling Group for dynamic scaling | ✅ Complete |
| **Secrets Management** | Integrated External Secrets Operator with AWS Secrets Manager | ✅ Complete |
| **Network Security** | Enforced Kubernetes Network Policies for traffic control | ✅ Complete |
| **Unified Access** | Single URL access via Ingress with path-based routing | ✅ Complete |
| **One-Click Deployment** | Terraform automation with GitHub Actions and manual approval | ✅ Complete |

---

## 🎁 Bonus Features

### Advanced Observability & Monitoring

| **Feature** | **Implementation** | **Status** |
|-------------|-------------------|------------|
| **Metrics Collection** | Deployed Prometheus + Grafana monitoring stack | ✅ Complete |
| **Log Aggregation** | Implemented OpenSearch + Fluent Bit logging solution | ✅ Complete |
| **DevOps Tool Access** | Live URLs for all observability and GitOps tools via Ingress | ✅ Complete |

---

## 🏗️ Architecture

The solution follows a microservices architecture deployed on AWS EKS with comprehensive monitoring and security:

![Architecture Diagram](fampay_architecture.png)

### Key Components:
- **EKS Cluster** - Managed Kubernetes service
- **Auto Scaling Groups** - Dynamic node scaling
- **Application Load Balancer** - Traffic distribution
- **External Secrets Operator** - Secure secrets management
- **Prometheus & Grafana** - Metrics and visualization
- **OpenSearch & Fluent Bit** - Centralized logging
- **Network Policies** - Security and traffic control

---

## 📚 Application Repositories

The project consists of two microservices with their respective repositories:

- **Bran Service**: [https://github.com/akash202k/bran](https://github.com/akash202k/bran)
- **Hodr Service**: [https://github.com/akash202k/hodr](https://github.com/akash202k/hodr)

---

## 🔧 Configuration Notes

- Ensure AWS credentials are properly configured before deployment
- The infrastructure setup creates all necessary AWS resources
- Application deployment script handles Kubernetes manifests and configurations
- All services are accessible through a single ingress endpoint
- Monitoring and logging tools are automatically configured and accessible

---
