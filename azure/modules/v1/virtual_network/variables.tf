variable "virtual_networks" {
  type = map(object(
    {
      cidrs          = list(string)
      resource_group = string
      tags           = map(string)
    }
  ))
}