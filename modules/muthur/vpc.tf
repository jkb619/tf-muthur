locals {
  subnet_count_public  = 2
  subnet_count_private = 2

  subnet_cidr_newbit = 24 - element(split("/", var.vpc_cidr_block), 1)
  subnet_cidrs_public = flatten([
    for index in range(local.subnet_count_public) : [
      cidrsubnet(var.vpc_cidr_block, local.subnet_cidr_newbit, index)
    ]
  ])
  subnet_cidrs_private = flatten([
    for index in range(local.subnet_count_public, local.subnet_count_public + local.subnet_count_private) : [
      cidrsubnet(var.vpc_cidr_block, local.subnet_cidr_newbit, index)
    ]
  ])

  subnet_private_ids = aws_subnet.muthur_privates.*.id
  subnet_public_ids  = aws_subnet.muthur_publics.*.id
}

resource "aws_vpc" "muthur" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags                 = merge(local.tags_rendered, tomap({"Name" = "muthur-${terraform.workspace}"}))
}

resource "aws_subnet" "muthur_publics" {
  count             = length(local.subnet_cidrs_public)
  availability_zone = element(local.server_availability_zones, count.index)
  cidr_block        = element(local.subnet_cidrs_public, count.index)
  tags              = merge(local.tags_rendered, tomap({"Name" = format("muthur-public-%d-${terraform.workspace}", count.index)}))
  vpc_id            = aws_vpc.muthur.id
}

resource "aws_subnet" "muthur_privates" {
  count             = length(local.subnet_cidrs_private)
  availability_zone = element(local.server_availability_zones, count.index)
  cidr_block        = element(local.subnet_cidrs_private, count.index)
  tags              = merge(local.tags_rendered, tomap({"Name" = format("muthur-private-%d-${terraform.workspace}", count.index)}))
  vpc_id            = aws_vpc.muthur.id
}

resource "aws_route_table" "muthur_public" {
  vpc_id = aws_vpc.muthur.id
  tags   = merge(local.tags_rendered, tomap({"Name" = "muthur-public-${terraform.workspace}"}))
}

resource "aws_route_table" "muthur_private" {
  vpc_id = aws_vpc.muthur.id
  tags   = merge(local.tags_rendered, tomap({"Name" = "muthur-private-${terraform.workspace}"}))
}

resource "aws_route_table_association" "public_table" {
  count          = length(local.subnet_public_ids)
  subnet_id      = element(local.subnet_public_ids, count.index)
  route_table_id = aws_route_table.muthur_public.id
}

resource "aws_route_table_association" "private_table" {
  count          = length(local.subnet_private_ids)
  subnet_id      = element(local.subnet_private_ids, count.index)
  route_table_id = aws_route_table.muthur_private.id
}

resource "aws_internet_gateway" "muthur" {
  vpc_id = aws_vpc.muthur.id
  tags   = merge(local.tags_rendered, tomap({"Name" = "muthur-gateway-${terraform.workspace}"}))
}

resource "aws_route" "muthur_internet_gw" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.muthur.id
  route_table_id         = aws_route_table.muthur_public.id
}

output internet_gateway_arn {
  description = "The ARN of the Internet Gateway allowing internet access to public subnets in the muthur VPC."
  value       = aws_internet_gateway.muthur.arn
}

output internet_gateway_id {
  description = "The ID of the Internet Gateway allowing internet access to public subnets in the muthur VPC."
  value       = aws_internet_gateway.muthur.id
}

output subnet_public_arns {
  description = "The ARN of the public subnets housing the server autoscaling group and load balancer."
  value       = aws_subnet.muthur_publics.*.arn
}

output subnet_public_azs {
  description = "The availability zones of the public subnets housing the server autoscaling group and load balancer."
  value       = aws_subnet.muthur_publics.*.availability_zone
}

output subnet_public_ids {
  description = "The IDs of the public subnets housing the server autoscaling group and load balancer."
  value       = local.subnet_public_ids
}

output subnet_private_arns {
  description = "The ARN of the private subnets housing the fargate muthur task."
  value       = aws_subnet.muthur_privates.*.arn
}

output subnet_private_azs {
  description = "The availability zones of the private subnets housing the fargate muthur task."
  value       = aws_subnet.muthur_privates.*.availability_zone
}

output subnet_private_ids {
  description = "The IDs of the private subnets housing the fargate muthur task."
  value       = local.subnet_private_ids
}

output vpc_arn {
  description = "The ARN of the muthur VPC housing all created and eligible resources."
  value       = aws_vpc.muthur.arn
}

output vpc_cidr_block {
  description = "The CIDR block of the muthur VPC housing all created and eligible resources."
  value       = aws_vpc.muthur.cidr_block
}

output vpc_route_table_public_id {
  description = "The public route table for the muthur VPC."
  value       = aws_route_table.muthur_public.id
}

output vpc_route_table_private_id {
  description = "The private route table for the muthur VPC."
  value       = aws_route_table.muthur_private.id
}

output vpc_id {
  description = "The ID of the muthur VPC housing all created and eligible resources."
  value       = aws_vpc.muthur.id
}
