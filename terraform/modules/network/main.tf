data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs                  = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  private_subnets      = var.private_subnet_cidrs
  public_subnets       = var.public_subnet_cidrs
  enable_dns_hostnames = true
  enable_dns_support   = true

  # IPv6: request an Amazon-provided /56 and an egress-only IGW for private subnets
  enable_ipv6                         = true

  # Carve unique /64s out of the VPC's /56 for each subnet
  public_subnet_ipv6_prefixes  = range(length(var.public_subnet_cidrs))
  private_subnet_ipv6_prefixes = range(
    length(var.public_subnet_cidrs),
    length(var.public_subnet_cidrs) + length(var.private_subnet_cidrs),
  )

  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = true

  # DNS64: synthesize AAAA records for IPv4-only destinations
  public_subnet_enable_dns64  = true
  private_subnet_enable_dns64 = true
}


# resource "aws_vpc" "this" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#
#   tags = { Name = "${var.name_prefix}-vpc" }
# }
#
# resource "aws_internet_gateway" "this" {
#   vpc_id = aws_vpc.this.id
#
#   tags = { Name = "${var.name_prefix}-igw" }
# }
#
# resource "aws_subnet" "public" {
#   count                   = length(var.public_subnet_cidrs)
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = var.public_subnet_cidrs[count.index]
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
#   map_public_ip_on_launch = true
#
#   tags = {
#     Name = "${var.name_prefix}-public-${count.index + 1}"
#     Tier = "public"
#   }
# }
#
# resource "aws_subnet" "private" {
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = var.private_subnet_cidrs[0]
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   map_public_ip_on_launch = false
#
#   tags = {
#     Name = "${var.name_prefix}-private-a"
#     Tier = "private"
#   }
# }
#
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.this.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.this.id
#   }
#
#   tags = { Name = "${var.name_prefix}-public-rt" }
# }

# resource "aws_route_table_association" "public" {
#   count          = length(aws_subnet.public)
#   subnet_id      = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.public.id
# }
#
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.this.id
#
#   tags = { Name = "${var.name_prefix}-private-rt" }
# }
#
# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }
#
# # No NAT gateway to keep dev cost low. Private instances are managed via AWS Systems Manager.
# resource "aws_security_group" "vpce" {
#   name        = "${var.name_prefix}-vpce-sg"
#   description = "HTTPS from VPC to interface endpoints"
#   vpc_id      = aws_vpc.this.id
#
#   ingress {
#     description = "HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.this.cidr_block]
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = { Name = "${var.name_prefix}-vpce-sg" }
# }

# locals {
#   interface_endpoints = toset([
#     "ssm",
#     "ssmmessages",
#     "ec2messages",
#     "logs",
#     "monitoring"
#   ])
# }
#
# resource "aws_vpc_endpoint" "interface" {
#   for_each            = local.interface_endpoints
#   vpc_id              = aws_vpc.this.id
#   service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.private.id]
#   security_group_ids  = [aws_security_group.vpce.id]
#   private_dns_enabled = true
#
#   tags = { Name = "${var.name_prefix}-${each.key}-vpce" }
# }
#
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${var.aws_region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.private.id]
#
#   tags = { Name = "${var.name_prefix}-s3-vpce" }
# }
