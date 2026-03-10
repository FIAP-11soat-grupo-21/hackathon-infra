# Este módulo S3 é gerenciado separadamente dos demais
# Será ignorado nos comandos run-all para evitar erros se o bucket já existir
# Para aplicar/destruir este módulo, execute diretamente: terragrunt apply/destroy neste diretório

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

dependency "sns_topic_chunk_uploaded" {
  config_path = "../../SNS/chunk-uploaded"

  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-2:123456789012:mock-topic"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name   = local.parent.locals.project.name
}

inputs = {
  bucket_name = "chunk-bucket"
  enable_versioning = true
  enable_encryption = true

  enable_notifications = true
  notification_topic_arn = dependency.sns_topic_chunk_uploaded.outputs.topic_arn
  notification_events = ["s3:ObjectCreated:*"]

  kms_key_id = ""
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}

