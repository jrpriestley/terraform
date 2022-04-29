data "aws_security_group" "sg" {
  for_each = { for k, v in var.nics : v.name => v }

  tags = {
    Name = each.value.security_group
  }
}

data "aws_subnet" "subnet" {
  for_each = { for k, v in var.nics : v.name => v }

  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Name = each.value.subnet
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_network_interface" "nic" {
  for_each = { for k, v in var.nics : v.name => v }

  subnet_id       = data.aws_subnet.subnet[each.key].id
  security_groups = [data.aws_security_group.sg[each.key].id]

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}