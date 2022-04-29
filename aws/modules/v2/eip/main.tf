resource "aws_eip" "eip" {
  for_each = { for k, v in var.eips : v.name => v }

  vpc = true

  tags = {
    Name              = each.key
    terraform_managed = "true"
  }
}