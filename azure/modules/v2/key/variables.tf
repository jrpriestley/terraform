variable "keys" {
  type = list(object(
    {
      name           = string
      public_key     = string
      resource_group = string
      tags           = map(string)
    }
  ))
}