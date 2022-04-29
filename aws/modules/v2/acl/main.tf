data "aws_subnet" "subnet" {
  for_each = toset(flatten([for k1, v1 in var.acls : [for v2 in v1.subnets : [v2]]]))

  tags = {
    Name = each.key
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_network_acl" "acl" {
  for_each = { for k, v in var.acls : v.name => v }

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = [for v in each.value.subnets : data.aws_subnet.subnet[v].id]

  dynamic "egress" {
    for_each = each.value.egress

    content {
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      rule_no    = egress.value.rule_no
      protocol   = egress.value.protocol
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress

    content {
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      rule_no    = ingress.value.rule_no
      protocol   = ingress.value.protocol
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}