variable "nics" {
  type = list(object(
    {
      name           = string
      security_group = string
      subnet         = string
      tags           = map(string)
    },
  ))
}

variable "vpc" {
  type        = string
  description = "VPC for the network interface to reside in"
}