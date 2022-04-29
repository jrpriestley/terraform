variable "instances" {
  type = list(object(
    {
      ami_name       = string
      ami_owner      = string
      key_pair       = string
      name           = string
      security_group = string
      size           = string
      subnet         = string
      tags           = map(string)
    },
  ))
}

variable "vpc" {
  type        = string
  description = "VPC for the instance to reside in"
}