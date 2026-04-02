provider "aws" {
  region = "us-east-1"
}

variables {
  primary_cluster_name            = "test-primary"
  primary_cluster_instance_name   = "test-instance"
  database_username               = "admin"
  cluster_engine                  = "aurora-postgresql"
  cluster_engine_version          = "15.4"
  primary_database_subnet         = "test-subnet"  
  rds_instance_class              = "db.t3.medium"
  primary_instance_count          = 1
}

run "no_global_cluster_by_default" {
  command = plan  # unit test — no real resources created

  assert {
    condition     = length(aws_rds_global_cluster.global_cluster) == 0
    error_message = "Global cluster should not be created when create_global_cluster is false"
  }
}

run "primary_instance_count" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster_instance.primary_instance) == 1
    error_message = "Expected 1 primary instance"
  }
}

run "no_secondary_by_default" {
  command = plan

  assert {
    condition     = length(aws_rds_cluster.secondary) == 0
    error_message = "Secondary cluster should not be created when secondary_cluster_enabled is false"
  }
}

run "public_access_disabled_by_default" {
  command = plan

  assert {
    condition     = alltrue([for i in aws_rds_cluster_instance.primary_instance : i.publicly_accessible == false])
    error_message = "Instances should not be publicly accessible by default"
  }
}