module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name

  vpc_cidr              = var.vpc_cidr
  public_subnet_a_cidr  = var.public_subnet_a_cidr
  public_subnet_b_cidr  = var.public_subnet_b_cidr
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
}

resource "aws_ecr_repository" "threat_composer" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-app"
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  ecr_repository_url = aws_ecr_repository.threat_composer.repository_url
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs.id

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution
  ]
}
