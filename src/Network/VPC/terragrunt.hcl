include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/VPC?ref=main"
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_cidr = "10.0.1.0/24"
  public_subnet_cidr  = "10.0.2.0/24"
  vpc_name            = local.parent.locals.project.name
}

inputs = {
  vpc_cidr            = local.vpc_cidr
  vpc_name            = "vpc-${local.vpc_name}"
  private_subnet_cidr = local.private_subnet_cidr
  public_subnet_cidr  = local.public_subnet_cidr

  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}