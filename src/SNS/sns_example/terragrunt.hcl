include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/SNS?ref=main"
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"
}

dependency "VPC" {
  config_path = "../../Network/VPC"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name = local.parent.locals.project.name
}

inputs = {
  topic = {
    name = "SNS_example"
  }
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
