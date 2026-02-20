include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/cognito?ref=main"
}

dependency "AppRegistry" {
  config_path = "../AppRegistry"

  mock_outputs = {
    app_registry_application_tag = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}


locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))

  user_pool_name               = "users"
  allow_admin_create_user_only = false
  auto_verified_attributes     = ["email"]
  username_attributes          = []
  email_required               = true
  name_required                = true
  generate_secret              = true
  access_token_validity        = 60
  id_token_validity            = 60
  refresh_token_validity       = 30
}
