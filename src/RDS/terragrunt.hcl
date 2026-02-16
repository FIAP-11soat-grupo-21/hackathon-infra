include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/FIAP-11soat-grupo-21/infra-core.git//modules/RDS?ref=main"
}

dependency "AppRegistry" {
  config_path = "../AppRegistry"
}

dependency "VPC" {
  config_path = "../Network/VPC"
}

locals {
  parent = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
}

inputs = {
  project_common_tags = merge(local.parent.locals.common_tags, try(dependency.AppRegistry.outputs.app_registry_application_tag, {}))
  app_name = "${try(local.parent.locals.project.name, "project")}-${try(local.parent.locals.db_engine, "postgres")}-db"

  db_port              = try(local.parent.locals.db_port, 5432)
  db_allocated_storage = try(local.parent.locals.db_allocated_storage, 20)
  db_storage_type      = "gp2"
  db_engine            = try(local.parent.locals.db_engine, "postgres")
  db_engine_version    = try(local.parent.locals.db_engine_version, "13")
  db_instance_class    = try(local.parent.locals.db_instance_class, "db.t3.micro")
  db_username          = try(local.parent.locals.db_username, "postgres")

  private_subnets = dependency.VPC.outputs.private_subnets
  vpc_id          = dependency.VPC.outputs.vpc_id
}
