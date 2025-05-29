
# resource "aws_ecrpublic_repository" "fampay_ecr" {

#   repository_name = "fampay-demo" # Better name

#   catalog_data {
#     about_text    = "FamPay Demo Application"
#     architectures = ["x86-64"] # FIXED: Match your t2.small nodes
#     description   = "Demo application for FamPay EKS cluster"
#     # logo_image_blob   = filebase64("image.png")  # Optional - comment out if no image
#     operating_systems = ["Linux"]
#     usage_text        = "Docker image for FamPay demo application"
#   }

#   tags = {
#     Environment = "fampay"
#     Terraform   = "true"
#   }
# }


locals {
  applications = ["hodr", "bran"] # Your two applications
}

resource "aws_ecrpublic_repository" "fampay_apps" {
  for_each = toset(local.applications)

  repository_name = "fampay-${each.value}"

  catalog_data {
    about_text        = "FamPay ${title(each.value)} Application"
    architectures     = ["x86-64"]
    description       = "FamPay ${each.value} microservice for EKS cluster"
    operating_systems = ["Linux"]
    usage_text        = "Docker image for FamPay ${each.value} application"
  }

  tags = {
    Environment = "fampay"
    Terraform   = "true"
    Application = each.value
  }
}