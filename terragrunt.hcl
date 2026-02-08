locals {
  environment = "dev"
  project = {
    name        = "test"
    description = "Sem descrição"
  }
  common_tags = {
    Environment = local.environment
    ManagedBy   = "terragrunt"
  }
  bucket = "fiap-tc-terraform-846874"
  region = "us-east-2"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket  = "${local.bucket}"
    key     = "tech-challenge-project/${path_relative_to_include()}/terraform.tfstate"
    region  = "${local.region}"
    encrypt = true
  }
}
EOF
}