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
  default = "fampay-alb-2139775353.us-east-1.elb.amazonaws.com"
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