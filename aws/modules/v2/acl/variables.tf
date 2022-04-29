variable "acls" {
  type = list(object(
    {
      name    = string
      subnets = list(string)
      egress = list(object(
        {
          action     = string
          cidr_block = string
          rule_no    = number
          protocol   = string
          from_port  = number
          to_port    = number
        }
      ))
      ingress = list(object(
        {
          action     = string
          cidr_block = string
          rule_no    = number
          protocol   = string
          from_port  = number
          to_port    = number
        }
      ))
      tags = map(string)
    },
    )
  )
}

variable "vpc" {
  type        = string
  description = "VPC for the ACL to reside in"
}