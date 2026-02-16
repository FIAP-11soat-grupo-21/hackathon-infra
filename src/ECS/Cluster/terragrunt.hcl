include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/ECS-Cluster?ref=main"
}

dependency "GHCR_Secret" {
  config_path = "../../Secrets/GHCR"

  mock_outputs = {
    secret_arn = "arn:aws:secretsmanager:us-east-2:123456789012:secret:mock-secret"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

dependency "VPC" {
  config_path = "../../Network/VPC"

  mock_outputs = {
    vpc_id          = "vpc-mock"
    private_subnets = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"

  mock_outputs = {
    app_registry_application_tag = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name = local.parent.locals.project.name
}

inputs = {
  vpc_id             = dependency["VPC"].outputs.vpc_id
  project_name       = local.project_name
  private_subnet_ids = dependency["VPC"].outputs.private_subnets
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
