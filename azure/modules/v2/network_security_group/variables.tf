variable "network_security_groups" {
  type = list(object(
    {
      allow_same_security_group_traffic = bool
      deny_implicit_traffic             = bool
      name                              = string
      resource_group                    = string
      subnets                           = list(string)
      virtual_network                   = string
      tags                              = map(string)
    }
  ))
}