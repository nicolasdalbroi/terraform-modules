################################################################################
# DB Subnet Groups
################################################################################

resource "aws_db_subnet_group" "primary" {
  name        = "${var.primary_cluster_name}-subnet-group"
  description = "DB subnet group for ${var.primary_cluster_name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.primary_cluster_name}-subnet-group" })
}

resource "aws_db_subnet_group" "secondary" {
  count    = var.secondary_cluster_enabled ? 1 : 0
  provider = aws.secondary

  name        = "${var.secondary_cluster_name}-subnet-group"
  description = "DB subnet group for ${var.secondary_cluster_name}"
  subnet_ids  = var.secondary_subnet_ids

  tags = merge(var.tags, { Name = "${var.secondary_cluster_name}-subnet-group" })
}

################################################################################
# Global Cluster
################################################################################

resource "aws_rds_global_cluster" "global_cluster" {
  count                     = var.create_global_cluster == true ? 1 : 0
  global_cluster_identifier = local.global_cluster_identifier
  engine                    = local.global_engine
  engine_version            = local.global_engine_version
  database_name             = local.global_database_name

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Password
################################################################################

ephemeral "random_password" "database_password" {
  length           = "16"
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "db_password"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id                = aws_secretsmanager_secret.db_password.id
  secret_string_wo         = ephemeral.random_password.database_password.result
  secret_string_wo_version = 1
}

################################################################################
# Primary Cluster
################################################################################

resource "aws_rds_cluster" "primary_cluster" {
  cluster_identifier                  = var.primary_cluster_name
  engine                              = var.create_global_cluster == true ? aws_rds_global_cluster.global_cluster[0].engine : var.cluster_engine
  engine_version                      = var.create_global_cluster == true ? aws_rds_global_cluster.global_cluster[0].engine_version : var.cluster_engine_version
  global_cluster_identifier           = var.create_global_cluster == true ? aws_rds_global_cluster.global_cluster[0].id : ""
  master_username                     = var.database_username
  master_password_wo                  = var.master_password_override != null ? var.master_password_override : aws_secretsmanager_secret_version.db_password.secret_string_wo
  master_password_wo_version          = var.master_password_override != null ? 0 : aws_secretsmanager_secret_version.db_password.secret_string_wo_version
  db_subnet_group_name                = aws_db_subnet_group.primary.name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  iam_roles                           = var.iam_database_authentication_enabled == true ? var.iam_roles : [""]

  tags = merge(var.tags, { Name = var.primary_cluster_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_instance" "primary_instance" {
  count              = var.primary_instance_count
  identifier         = "${var.primary_cluster_instance_name}-${count.index}"
  engine             = aws_rds_cluster.primary_cluster.engine
  engine_version     = aws_rds_cluster.primary_cluster.engine_version
  instance_class     = var.rds_instance_class
  cluster_identifier = aws_rds_cluster.primary_cluster.cluster_identifier
  publicly_accessible = var.public_access

  tags = merge(var.tags, { Name = "${var.primary_cluster_instance_name}-${count.index}" })

  depends_on = [aws_rds_cluster.primary_cluster]

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Secondary Cluster
################################################################################

resource "aws_rds_cluster" "secondary" {
  count    = var.secondary_cluster_enabled == true ? 1 : 0
  provider = aws.secondary

  engine                              = aws_rds_cluster.primary_cluster.engine
  engine_version                      = aws_rds_cluster.primary_cluster.engine_version
  cluster_identifier                  = var.secondary_cluster_name
  global_cluster_identifier           = var.create_global_cluster == true ? aws_rds_global_cluster.global_cluster[0].id : ""
  skip_final_snapshot                 = true
  db_subnet_group_name                = aws_db_subnet_group.secondary[0].name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  iam_roles                           = var.iam_database_authentication_enabled == true ? var.iam_roles : [""]

  tags = merge(var.tags, { Name = var.secondary_cluster_name })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      replication_source_identifier
    ]
  }

  depends_on = [aws_rds_cluster_instance.primary_instance]
}

resource "aws_rds_cluster_instance" "secondary_cluster_instance" {
  provider           = aws.secondary
  count              = var.secondary_cluster_enabled ? var.secondary_instance_count : 0
  identifier         = "${var.secondary_cluster_instance_name}-${count.index}"
  engine             = aws_rds_cluster.primary_cluster.engine
  engine_version     = aws_rds_cluster.primary_cluster.engine_version
  instance_class     = var.rds_instance_class
  cluster_identifier = aws_rds_cluster.secondary[0].cluster_identifier

  tags = merge(var.tags, { Name = "${var.secondary_cluster_instance_name}-${count.index}" })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_rds_cluster.secondary]
}
