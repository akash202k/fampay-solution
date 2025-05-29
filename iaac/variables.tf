variable "aws_region" {
  default = "us-east-1"
}

variable "cluster_name" {
  default = "fampay-eks-cluster"
}

variable "cluster_version" {
  default = "1.32"
}

variable "alb_dns_name" {
  default = "k8s-fampayin-fampayin-21113d1298-628572169.us-east-1.elb.amazonaws.com"
}

variable "alb_hosted_zone_id" {
  default = "Z35SXDOTRQ7X7K"
}

variable "subdomain_name" {
  default = "dayxcode.com"
}

variable "domain" {
  default = "dayxcode.com"
}