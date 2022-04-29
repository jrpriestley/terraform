variable "acls" {
  type = map(object(
    {
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
  type = string
}