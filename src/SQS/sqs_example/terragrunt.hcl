include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/SQS?ref=main"
}

dependency "AppRegistry" {
  config_path  = "../../AppRegistry"
  skip_outputs = true
}

dependency "sns_order_error" {
  config_path  = "../../SNS/sns_example"
  skip_outputs = true
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name = local.parent.locals.project.name
}

inputs = {
  queue_name                 = "SQS_example"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 30
  sns_topic_arns             = [dependency.sns_order_error.outputs.topic_arn]

  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
