variable "route_tables" {
  type = list(object(
    {
      name    = string
      routes  = map(string)
      subnets = list(string)
      tags    = map(string)
    }
    )
  )
}

variable "vpc" {
  type        = string
  description = "VPC for the route tables to reside in"
}