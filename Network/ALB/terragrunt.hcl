include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/ALB?ref=main"
}


dependency "AppRegistry" {
  config_path = "../../AppRegistry"
}

dependency "VPC" {
  config_path = "../VPC"
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