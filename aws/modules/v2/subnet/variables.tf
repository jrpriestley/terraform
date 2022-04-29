variable "subnets" {
  type = list(object(
    {
      availability_zone       = string
      cidr                    = string
      create_ngw              = bool
      map_public_ip_on_launch = bool
      name                    = string
      tags                    = map(string)
    },
  ))
}

variable "vpc" {
  type        = string
  description = "VPC for the subnets to reside in"
}