resource "aws_ec2_transit_gateway" "tgw" {
  amazon_side_asn = var.amazon_side_asn
  description     = var.description

  tags = merge(
    {
      Name              = var.description
      terraform_managed = "true"
    },
    var.tags
  )
}