mock_provider "aws" {
  mock_resource "aws_secretsmanager_secret_version" {
    defaults = {
      secret_string_wo         = "mock-password"
      secret_string_wo_version = 1
    }
  }

  mock_resource "aws_rds_cluster" {
    defaults = {
      master_password_wo         = "mock-password"
      master_password_wo_version = 1
    }
  }
}

mock_provider "aws" {
  alias = "secondary"
}

variables {
  create_global_cluster               = true
  global_cluster_identifier           = "global-cluster"
  global_engine               = "aurora-postgresql"
  master_password_override            = "mock-password"
  primary_cluster_name                = "test-primary"
  primary_cluster_instance_name       = "test-instance"
  secondary_cluster_name              = "test-secondary"
  secondary_cluster_instance_name     = "test-secondary-instance"
  database_username                   = "admin"
  cluster_engine                      = "aurora-postgresql"
  cluster_engine_version              = "15.4"
  primary_database_subnet             = "test-subnet"
  secondary_database_subnet           = "test-secondary-subnet"
  rds_instance_class                  = "db.t3.medium"
  primary_instance_count              = 2
  secondary_cluster_enabled = true
  secondary_instance_count            = 1
  iam_database_authentication_enabled = false
  iam_roles                           = []
}

run "global_cluster_created" {
  command = plan

  assert {
    condition     = length(aws_rds_global_cluster.global_cluster) == 1
    error_message = "Global cluster should be created when create_global_cluster is true"
  }
}

run "primary_uses_global_engine" {
  command = plan

  assert {
    condition     = aws_rds_cluster.primary_cluster.engine == aws_rds_global_cluster.global_cluster[0].engine
    error_message = "Primary cluster engine should match global cluster engine"
  }
}

run "secondary_cluster_created" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster.secondary) == 1
    error_message = "Secondary cluster should be created when secondary_cluster_enabled is true"
  }
}