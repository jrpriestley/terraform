locals {
  security_group_rules = flatten([
    for k1, v1 in var.security_group_rules : [
      for k2, v2 in v1 : [
        for v3 in v2 : [
          for v4 in v3.endpoints : {
            name                  = substr(v4, 0, 2) == "sg" && k2 == "egress" ? substr(v4, 3, -1) : k1
            direction             = k2
            description           = v3.description
            from_port             = v3.from_port
            to_port               = v3.to_port
            protocol              = v3.protocol
            cidr_blocks           = substr(v4, 0, 4) == "cidr" ? substr(v4, 5, -1) : ""
            source_security_group = substr(v4, 0, 2) == "sg" ? (k2 == "egress" ? k1 : substr(v4, 3, -1)) : ""
          }
        ]
      ]
    ]
  ])
}

data "aws_security_group" "security_group" {
  for_each = var.security_group_rules

  tags = {
    Name = each.key
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_security_group_rule" "security_group_rule_custom_cidr" {
  for_each = { for o in local.security_group_rules : format("%s_%s_%s_%s_%s", o.name, o.direction, o.cidr_blocks, o.protocol, o.to_port) => o if o.cidr_blocks != "" }

  security_group_id = data.aws_security_group.security_group[each.value.name].id
  cidr_blocks       = [each.value.cidr_blocks]
  description       = each.value.description
  from_port         = each.value.from_port
  protocol          = each.value.protocol
  to_port           = each.value.to_port
  type              = each.value.direction
}

resource "aws_security_group_rule" "security_group_rule_custom_security_group" {
  for_each = { for o in local.security_group_rules : format("%s_%s_%s_%s_%s", o.name, o.direction, o.source_security_group, o.protocol, o.to_port) => o if o.source_security_group != "" }

  security_group_id        = data.aws_security_group.security_group[each.value.name].id
  source_security_group_id = data.aws_security_group.security_group[each.value.source_security_group].id
  description              = each.value.description
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  to_port                  = each.value.to_port
  type                     = each.value.direction
}