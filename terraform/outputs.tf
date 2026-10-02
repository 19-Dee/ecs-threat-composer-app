output "vpc_id" {
  description = "ID of the ECS VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL of the Threat Composer ECR repository"
  value       = aws_ecr_repository.threat_composer.repository_url
}
