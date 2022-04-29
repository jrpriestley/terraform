variable "subnets" {
  type = map(object(
    {
      availability_zone       = string
      cidr                    = string
      create_ngw              = bool
      map_public_ip_on_launch = bool
      tags                    = map(string)
    },
  ))
}

variable "vpc" {
  type = string
}