variable "public_ips" {
  type = list(object(
    {
      allocation_method = string
      name              = string
      resource_group    = string
      sku               = string
      tags              = map(string)
    }
  ))
}