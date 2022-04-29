data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_security_group" "sg" {
  for_each = { for k, v in var.security_groups : v.name => v }

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

resource "aws_security_group_rule" "sgr_intra" {
  for_each = { for k, v in var.security_groups : v.name => v if v.allow_same_security_group_traffic }

  security_group_id        = aws_security_group.sg[each.key].id
  source_security_group_id = aws_security_group.sg[each.key].id
  type                     = "ingress"
  description              = "allow any from same security group"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
}