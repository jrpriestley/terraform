data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_subnet" "subnet" {
  for_each = var.subnets

  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  vpc_id                  = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_eip" "eip" {
  for_each = { for k, v in var.subnets : k => v if v.create_ngw == true }

  vpc = true

  tags = {
    Name              = each.key
    terraform_managed = "true"
  }
}

resource "aws_nat_gateway" "ngw" {
  for_each = { for k, v in var.subnets : k => v if v.create_ngw == true }

  allocation_id = aws_eip.eip[each.key].id
  subnet_id     = aws_subnet.subnet[each.key].id

  tags = {
    Name              = each.key
    terraform_managed = "true"
  }
}