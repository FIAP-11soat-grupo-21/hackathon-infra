include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/ALB?ref=main"
}


dependency "AppRegistry" {
  config_path = "../../AppRegistry"

  mock_outputs = {
    app_registry_application_tag = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependency "VPC" {
  config_path = "../VPC"

  mock_outputs = {
    vpc_id          = "vpc-mock"
    private_subnets = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
}

dependencies {
  paths = [
    "../VPC",
    "../../AppRegistry"
  ]
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  vpc_id              = dependency["VPC"].outputs.vpc_id
  private_subnet_ids  = dependency["VPC"].outputs.private_subnets
  loadbalancer_name   = "alb-${local.parent.locals.project.name}-internal-lb"
  is_internal         = true
  app_port_init_range = 8080
  app_port_end_range  = 8090
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}