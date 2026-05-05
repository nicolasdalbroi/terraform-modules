################################################################################
# Test: Complete VPC — public + private + database + redshift subnets,
#       HA NAT (one per AZ), custom NACLs
################################################################################

mock_provider "aws" {}

variables {
  region = "us-east-1"
  name           = "test-complete"
  vpc_cidr_block = "10.0.0.0/16"

  public_subnets = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  private_subnets = {
    "us-east-1a" = "10.0.10.0/24"
    "us-east-1b" = "10.0.11.0/24"
  }

  database_subnets = {
    "us-east-1a" = "10.0.20.0/24"
    "us-east-1b" = "10.0.21.0/24"
  }

  redshift_subnets = {
    "us-east-1a" = "10.0.30.0/24"
    "us-east-1b" = "10.0.31.0/24"
  }

  create_igw         = true
  enable_nat_gateway = true
  single_nat_gateway = false

  nat_gateway_azs = {
    "us-east-1a" = true
    "us-east-1b" = true
  }

  create_public_nacl  = true
  create_private_nacl = true

  tags = { Environment = "test" }
}

run "all_subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.public_subnet) == 2
    error_message = "Expected 2 public subnets"
  }

  assert {
    condition     = length(aws_subnet.private_subnet) == 2
    error_message = "Expected 2 private subnets"
  }

  assert {
    condition     = length(aws_subnet.database_subnet) == 2
    error_message = "Expected 2 database subnets"
  }

  assert {
    condition     = length(aws_subnet.redshift_subnet) == 2
    error_message = "Expected 2 Redshift subnets"
  }
}

run "ha_nat_gateways_created" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Expected 2 NAT Gateways for HA (one per AZ)"
  }

  assert {
    condition     = length(aws_eip.nat) == 2
    error_message = "Expected 2 EIPs for HA NAT"
  }
}

run "private_route_tables_per_az" {
  command = plan

  assert {
    condition     = length(aws_route_table.private) == 2
    error_message = "Expected one private route table per AZ"
  }
}

run "nacls_created" {
  command = plan

  assert {
    condition     = length(aws_network_acl.public) == 1
    error_message = "Expected one public NACL"
  }

  assert {
    condition     = length(aws_network_acl.private) == 1
    error_message = "Expected one private NACL"
  }
}

run "public_nacl_has_inbound_rules" {
  command = plan

  assert {
    condition     = length(aws_network_acl_rule.public_inbound) > 0
    error_message = "Expected at least one public NACL inbound rule"
  }
}

run "public_nacl_has_outbound_rules" {
  command = plan

  assert {
    condition     = length(aws_network_acl_rule.public_outbound) > 0
    error_message = "Expected at least one public NACL outbound rule"
  }
}
