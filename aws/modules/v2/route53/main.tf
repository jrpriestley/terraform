data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_route53_zone" "zone" {
  name = var.name

  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
}

resource "aws_route53_record" "record" {
  for_each = { for k, v in var.records : v.name => v }

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.key
  type    = upper(each.value.type) # AWS/Terraform requires this to be in UPPERCASE
  ttl     = each.value.ttl
  records = each.value.records
}