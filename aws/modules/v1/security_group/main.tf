data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_security_group" "security_group" {
  for_each = var.security_groups

  name        = each.key
  description = each.key
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_security_group_rule" "security_group_rule_same_security_group" {
  for_each = { for k, v in var.security_groups : k => v if v.allow_same_security_group_traffic }

  security_group_id        = aws_security_group.security_group[each.key].id
  source_security_group_id = aws_security_group.security_group[each.key].id
  type                     = "ingress"
  description              = "allow any from same security group"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
}