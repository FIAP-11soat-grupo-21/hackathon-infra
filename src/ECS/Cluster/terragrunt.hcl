include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/ECS-Cluster?ref=main"
}

dependency "GHCR_Secret" {
  config_path  = "../../Secrets/GHCR"
  skip_outputs = true
}

dependency "VPC" {
  config_path  = "../../Network/VPC"
  skip_outputs = true
}

dependency "AppRegistry" {
  config_path  = "../../AppRegistry"
  skip_outputs = true
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
