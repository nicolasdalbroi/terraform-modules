resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostname
  enable_dns_support   = var.enable_dns_support
  region               = var.region
  tags                 = var.tags
}

# Public subnet configuration

resource "aws_subnet" "public_subnet" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

# Private subnet configuration

resource "aws_subnet" "private_subnet" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

}

# Database subnet configuration

resource "aws_subnet" "database_subnet" {
  for_each          = var.database_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
}

resource "aws_subnet" "redshift_subnet" {
  for_each          = var.redshift_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
}

# Internet Gateway

resource "aws_internet_gateway" "this" {
  count  = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# Route tables public

resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_igw" {
  count = length(var.public_subnets) > 0 && var.create_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# NAT Gateway
locals {
  # When single_nat_gateway, only provision in the first AZ
  effective_nat_azs = var.single_nat_gateway ? { for k, v in var.nat_gateway_azs : k => v if k == sort(keys(var.nat_gateway_azs))[0] } : var.nat_gateway_azs
}

resource "aws_eip" "nat" {
  for_each   = var.enable_nat_gateway ? local.effective_nat_azs : {}
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-eip-${each.key}" })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each      = var.enable_nat_gateway ? local.effective_nat_azs : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-${each.key}" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? var.private_subnets : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # Single mode → always point to the one NAT; HA mode → point to per-AZ NAT
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[sort(keys(local.effective_nat_azs))[0]].id : aws_nat_gateway.this[each.key].id
}

# Network ACLs — Public

resource "aws_network_acl" "public" {
  count = var.create_public_nacl && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.public_subnet : s.id]

  tags = merge(var.tags, { Name = "${var.name}-public-nacl" })
}

resource "aws_network_acl_rule" "public_inbound" {
  for_each = var.create_public_nacl && length(var.public_subnets) > 0 ? { for r in var.public_nacl_inbound_rules : r.rule_number => r } : {}

  network_acl_id = aws_network_acl.public[0].id
  egress         = false
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  for_each = var.create_public_nacl && length(var.public_subnets) > 0 ? { for r in var.public_nacl_outbound_rules : r.rule_number => r } : {}

  network_acl_id = aws_network_acl.public[0].id
  egress         = true
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
}

# Network ACLs — Private

resource "aws_network_acl" "private" {
  count = var.create_private_nacl && length(var.private_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private_subnet : s.id]

  tags = merge(var.tags, { Name = "${var.name}-private-nacl" })
}

resource "aws_network_acl_rule" "private_inbound" {
  for_each = var.create_private_nacl && length(var.private_subnets) > 0 ? { for r in var.private_nacl_inbound_rules : r.rule_number => r } : {}

  network_acl_id = aws_network_acl.private[0].id
  egress         = false
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  for_each = var.create_private_nacl && length(var.private_subnets) > 0 ? { for r in var.private_nacl_outbound_rules : r.rule_number => r } : {}

  network_acl_id = aws_network_acl.private[0].id
  egress         = true
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  from_port      = lookup(each.value, "from_port", null)
  to_port        = lookup(each.value, "to_port", null)
}
