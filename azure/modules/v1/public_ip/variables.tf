variable "public_ips" {
  type = map(object(
    {
      allocation_method = string
      resource_group    = string
      sku               = string
      tags              = map(string)
    }
  ))
}