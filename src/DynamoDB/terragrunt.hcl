include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/Dynamo?ref=main"
}

dependency "AppRegistry" {
  config_path = "../AppRegistry"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))

  name = "${try(local.parent.locals.project.name, "project")}-table"

  hash_key      = try(local.parent.locals.dynamodb_hash_key, "id")
  hash_key_type = try(local.parent.locals.dynamodb_hash_key_type, "S")
  billing_mode  = try(local.parent.locals.dynamodb_billing_mode, "PAY_PER_REQUEST")

  secondary_indexes = try(local.parent.locals.dynamodb_secondary_indexes, [
    {
      name            = "cpf-index"
      hash_key        = "cpf"
      range_key       = "S"
      projection_type = "ALL"
    },
    {
      name            = "email-index"
      hash_key        = "email"
      range_key       = "S"
      projection_type = "ALL"
    }
  ])

  range_key = try(local.parent.locals.dynamodb_range_keys, [
    {
      name = "cpf"
      type = "S"
    },
    {
      name = "email"
      type = "S"
    }
  ])
}
