variable "route_tables" {
  type = map(object(
    {
      routes  = map(string)
      subnets = list(string)
      tags    = map(string)
    }
    )
  )
}

variable "vpc" {
  type = string
}