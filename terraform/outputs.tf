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

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs.task_definition_arn
}

output "ecs_security_group_id" {
  description = "Security group ID of the ECS tasks"
  value       = aws_security_group.ecs.id
}

output "ecs_service_name" {
  description = "Name of the ECS Fargate service"
  value       = module.ecs.service_name
}
