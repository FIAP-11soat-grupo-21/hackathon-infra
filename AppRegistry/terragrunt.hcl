include {
  path = find_in_parent_folders()
}


terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/APP-Registry?ref=main"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  project_name        = local.parent.locals.project.name
  project_description = local.parent.locals.project.description
  environment         = local.parent.locals.environment
}