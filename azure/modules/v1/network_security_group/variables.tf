variable "network_security_groups" {
  type = map(object(
    {
      allow_same_security_group_traffic = bool
      deny_implicit_traffic             = bool
      resource_group                    = string
      virtual_network                   = string
      subnets                           = list(string)
      rules = map(list(object(
        {
          description = string
          priority    = number
          access      = string
          protocol    = string
          from_port   = list(string)
          to_port     = list(string)
          source      = list(string)
          destination = list(string)
        }
      )))
      tags = map(string)
    }
  ))
}