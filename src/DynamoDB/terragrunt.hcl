include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/DynamoDB?ref=main"
}

dependency "VPC" {
  config_path = "../../Network/VPC"
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name = local.parent.locals.project.name
}


