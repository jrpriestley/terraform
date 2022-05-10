variable "network_security_groups" {
  type = list(object(
    {
      allow_intra_inbound    = bool
      allow_intra_outbound   = bool
      deny_implicit_inbound  = bool
      deny_implicit_outbound = bool
      name                   = string
      resource_group         = string
      subnets                = list(string)
      virtual_network        = string
      tags                   = map(string)
    }
  ))
}