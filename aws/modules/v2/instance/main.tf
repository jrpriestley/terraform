data "aws_ami" "ami" {
  for_each = { for k, v in var.instances : v.name => v }

  most_recent = true

  filter {
    name   = "name"
    values = [each.value.ami_name]
  }

  owners = [each.value.ami_owner]
}

data "aws_security_group" "sg" {
  for_each = { for k, v in var.instances : v.name => v }

  tags = {
    Name = each.value.security_group
  }
}

data "aws_subnet" "subnet" {
  for_each = { for k, v in var.instances : v.name => v }

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

module "nic" {
  for_each = { for k, v in var.instances : v.name => v }

  nics = [
    {
      name           = each.key
      security_group = each.value.security_group
      subnet         = each.value.subnet
      tags = {
      }
    },
  ]

  source = "../nic"
  vpc    = var.vpc
}

resource "aws_instance" "instance" {
  for_each = { for k, v in var.instances : v.name => v }

  ami           = data.aws_ami.ami[each.key].id
  instance_type = each.value.size
  key_name      = each.value.key_pair

  network_interface {
    network_interface_id = module.nic.aws_network_interface.nic[each.key].id
    device_index         = 0
  }

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}