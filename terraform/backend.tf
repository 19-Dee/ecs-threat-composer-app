terraform {
  backend "s3" {
    bucket       = "dee-ecs-threat-composer-tfstate"
    key          = "ecs/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
