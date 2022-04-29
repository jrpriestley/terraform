variable "virtual_network_gateways" {
  type = map(object(
    {
      active_active   = bool
      enable_bgp      = bool
      public_ip       = string
      resource_group  = string
      sku             = string
      subnet          = string
      type            = string
      virtual_network = string
      vpn_type        = string
      tags            = map(string)
    }
  ))
}