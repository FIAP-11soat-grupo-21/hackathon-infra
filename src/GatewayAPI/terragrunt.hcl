include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/API-Gateway?ref=main"
}

dependency "AppRegistry" {
  config_path = "../AppRegistry"
}

dependency "InternalALB" {
  config_path = "../Network/ALB"
}

dependency "VPC" {
  config_path = "../Network/VPC"
}

dependencies {
  paths = [
    "../Network/VPC",
    "../Network/ALB",
    "../AppRegistry"
  ]
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name          = local.parent.locals.project.name
}

inputs = {
  project_name          = local.project_name
  private_subnet_ids    = dependency["VPC"].outputs.private_subnets
  alb_security_group_id = dependency["InternalALB"].outputs.alb_security_group_id
  api_name              = "gwapi-${local.project_name}"
  gwapi_auto_deploy     = true
  stage_name            = "v1"

  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
