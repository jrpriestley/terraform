resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = var.dns_hostnames
  enable_dns_support   = var.dns_support

  tags = merge(
    {
      Name              = var.name
      terraform_managed = true
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  for_each = var.create_igw ? toset([var.name]) : toset([])

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name              = var.name
      terraform_managed = true
    },
    var.tags
  )
}