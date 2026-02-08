include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/SM?ref=main"
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name   = local.parent.locals.project.name
  secret_name    = "sa-${local.project_name}-ghcr"
  secret_content = {
    GHCR_USERNAME = "your-ghcr-username"
    GHCR_TOKEN    = "your-ghcr-token"
  }
}

inputs = {
  project_name = local.project_name
  secret_name  = local.secret_name
  secret_content = local.secret_content

}
