variable "security_groups" {
  type = map(object(
    {
      allow_same_security_group_traffic = bool
      tags                              = map(string)
    }
  ))
}

variable "vpc" {
  type = string
}