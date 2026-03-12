include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:FIAP-11soat-grupo-21/infra-core.git//modules/SQS?ref=main"
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

dependency "s3_chunk_bucket" {
  config_path = "../../S3/Chunks"

  mock_outputs = {
      bucket_arn = "arn:aws:s3:::mock-chunk-bucket"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  skip_outputs = false
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  project_name = local.parent.locals.project.name
}

inputs = {
  queue_name                 = "chunk-processor"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 300

  allow_s3_publish = true
  source_bucket_arn = dependency.s3_chunk_bucket.outputs.bucket_arn

  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
}
