include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/S3?ref=main"
}

dependency "AppRegistry" {
  config_path = "../../AppRegistry"

  mock_outputs = {
    app_registry_application_tag = {}
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name   = local.parent.locals.project.name
}

inputs = {
  bucket_name = "fiap-hackathon-lambda-content-44573"
  enable_versioning = true
  enable_encryption = true
  kms_key_id = ""
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
