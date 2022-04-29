variable "keys" {
  type = map(object(
    {
      resource_group = string
      public_key     = string
      tags           = map(string)
    }
  ))
}