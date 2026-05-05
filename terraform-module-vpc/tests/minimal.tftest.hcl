################################################################################
# Test: Minimal VPC — public subnets only, no NAT, no custom NACLs
################################################################################

mock_provider "aws" {}

variables {
  region         = "us-east-1"
  name           = "test-minimal"
  vpc_cidr_block = "10.0.0.0/16"

  public_subnets = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }

  private_subnets = {}

  create_igw         = true
  enable_nat_gateway = false
  single_nat_gateway = false

  create_public_nacl  = false
  create_private_nacl = false

  tags = { Environment = "test" }
}

run "vpc_is_created" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block does not match expected value"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_hostnames == true
    error_message = "DNS hostnames should be enabled by default"
  }

  assert {
    condition     = aws_vpc.this.enable_dns_support == true
    error_message = "DNS support should be enabled by default"
  }
}

run "public_subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.public_subnet) == 2
    error_message = "Expected 2 public subnets"
  }

  assert {
    condition     = aws_subnet.public_subnet["us-east-1a"].cidr_block == "10.0.1.0/24"
    error_message = "Public subnet CIDR for us-east-1a is incorrect"
  }

  assert {
    condition     = aws_subnet.public_subnet["us-east-1b"].cidr_block == "10.0.2.0/24"
    error_message = "Public subnet CIDR for us-east-1b is incorrect"
  }
}

run "no_private_subnets_created" {
  command = plan

  assert {
    condition     = length(aws_subnet.private_subnet) == 0
    error_message = "Expected no private subnets"
  }
}

run "igw_created" {
  command = plan

  assert {
    condition     = length(aws_internet_gateway.this) == 1
    error_message = "Expected one Internet Gateway"
  }
}

run "no_nat_gateway_created" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "Expected no NAT Gateways when enable_nat_gateway is false"
  }

  assert {
    condition     = length(aws_eip.nat) == 0
    error_message = "Expected no EIPs when enable_nat_gateway is false"
  }
}

run "no_custom_nacls_created" {
  command = plan

  assert {
    condition     = length(aws_network_acl.public) == 0
    error_message = "Expected no public NACL"
  }

  assert {
    condition     = length(aws_network_acl.private) == 0
    error_message = "Expected no private NACL"
  }
}
