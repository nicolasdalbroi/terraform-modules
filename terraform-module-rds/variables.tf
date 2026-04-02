variable "create_global_cluster" {
  type        = bool
  default     = false
  description = "Boolean value to determine wheter to create a global cluster"
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
  default = "t3.micro"
}

variable "primary_database_subnet" {
  type = string
}

variable "secondary_database_subnet" {
  type = string
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
  type = string
}