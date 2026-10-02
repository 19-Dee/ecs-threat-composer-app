output "certificate_arn" {
  value = aws_acm_certificate_validation.app.certificate_arn
}

output "app_domain_name" {
  value = var.app_domain_name
}
