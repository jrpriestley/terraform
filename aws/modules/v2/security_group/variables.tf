variable "security_groups" {
  type = list(object(
    {
      allow_same_security_group_traffic = bool
      name                              = string
      tags                              = map(string)
    }
  ))
}

variable "vpc" {
  type        = string
  description = "VPC for the security groups to reside in"
}