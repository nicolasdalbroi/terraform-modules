variable "create_global_cluster" {
  type        = bool
  default     = false
  description = "Boolean value to determine whether to create a global cluster"
}

variable "global_cluster_identifier" {
  type        = string
  default     = ""
  description = "Global cluster identifier"
}

variable "global_engine" {
  type    = string
  default = ""
}

variable "global_engine_version" {
  type    = string
  default = ""
}

variable "global_database_name" {
  type    = string
  default = ""
}

variable "primary_cluster_name" {
  type = string
}

variable "secondary_cluster_name" {
  type    = string
  default = ""
}

variable "database_username" {
  type = string
}

variable "cluster_engine" {
  type = string
}

variable "cluster_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

# Replaced primary_database_subnet (string) with subnet_ids (list)
# The module now creates the aws_db_subnet_group internally
variable "subnet_ids" {
  description = "List of subnet IDs for the primary DB subnet group (use database subnets)"
  type        = list(string)
}

# Replaced secondary_database_subnet (string) with secondary_subnet_ids (list)
variable "secondary_subnet_ids" {
  description = "List of subnet IDs for the secondary DB subnet group"
  type        = list(string)
  default     = []
}

variable "public_access" {
  type        = bool
  default     = false
  description = "Optional boolean to enable public endpoint for cluster instance"
}

variable "secondary_cluster_enabled" {
  type    = bool
  default = false
}

variable "primary_instance_count" {
  type    = number
  default = 1
}

variable "secondary_instance_count" {
  type    = number
  default = 1
}

variable "primary_cluster_instance_name" {
  type = string
}

variable "secondary_cluster_instance_name" {
  type    = string
  default = ""
}

variable "iam_database_authentication_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable IAM authentication to RDS cluster"
}

variable "iam_roles" {
  type        = list(string)
  default     = []
  description = "If IAM authentication is enabled provide a list of IAM roles"
}

variable "master_password_override" {
  type        = string
  default     = null
  sensitive   = true
  description = "Used for testing only. In production leave this null."
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
