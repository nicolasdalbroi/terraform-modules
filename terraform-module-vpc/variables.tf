# Generic variables
variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "tags" {
  description = "Tags for general VPC"
  type        = map(string)
  default     = {}
}


# VPC Variables
variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostname" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true

}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true

}

variable "region" {
  description = "Region for VPC"
  type        = string
  default = "us-east-1"
}

# Subnet variables

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones in the region"
  default     = []
}

variable "public_subnets" {
  description = "Map of AZ to CIDR block for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnets" {
  description = "Map of AZ to CIDR block for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnets" {
  description = "Map of AZ to CIDR block for database subnets"
  type        = map(string)
  default     = {}
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is `false`"
  type        = bool
  default     = false
}

variable "create_redshift_subnet" {
  description = "Toogle option to enable redshift subnets"
  type        = bool
  default     = false

}

variable "redshift_subnets" {
  description = "Map of AZ to CIDR block for redshift subnets"
  type        = map(string)
  default     = {}
}

# Internet Gateway
variable "create_igw" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = true
}

# NAT Gateway

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost saving). If false, one NAT per AZ (HA)."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways"
  type        = bool
  default     = false
}

variable "nat_gateway_azs" {
  description = <<-EOT
    Map of AZ to a placeholder value for NAT Gateway creation.
    Keys must match keys present in both public_subnets and private_subnets.
    Example: { us-east-1a = true, us-east-1b = true }
  EOT
  type        = map(bool)
  default     = {}
}

# Network ACLs — Public

variable "create_public_nacl" {
  description = "Whether to create a custom NACL for public subnets"
  type        = bool
  default     = false
}

variable "public_nacl_inbound_rules" {
  description = "List of inbound rules for the public NACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "tcp"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
    },
    {
      rule_number = 110
      protocol    = "tcp"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
    },
    {
      rule_number = 120
      protocol    = "tcp"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    }
  ]
}

variable "public_nacl_outbound_rules" {
  description = "List of outbound rules for the public NACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

# Network ACLs — Private

variable "create_private_nacl" {
  description = "Whether to create a custom NACL for private subnets"
  type        = bool
  default     = false
}

variable "private_nacl_inbound_rules" {
  description = "List of inbound rules for the private NACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "private_nacl_outbound_rules" {
  description = "List of outbound rules for the private NACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = optional(number)
    to_port     = optional(number)
  }))
  default = [
    {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}
