# Route53 hosted zone
resource "aws_route53_zone" "fampay_zone" {
  name = var.subdomain_name # Your root domain

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}

# ACM certificate
resource "aws_acm_certificate" "fampay_cert" {
  domain_name       = var.subdomain_name
  validation_method = "DNS"

  subject_alternative_names = [
    var.subdomain_name,
    "*.${var.subdomain_name}" # Wildcard for subdomains 
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "fampay"
    Terraform   = "true"
  }
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.fampay_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.fampay_zone.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "fampay_cert" {
  certificate_arn         = aws_acm_certificate.fampay_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# A record pointing to ALB
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.fampay_zone.zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

# Output nameservers
output "route53_nameservers" {
  value = aws_route53_zone.fampay_zone.name_servers
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.fampay_cert.arn
}