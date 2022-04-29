variable "resource_groups" {
  type = list(object(
    {
      location = string
      name     = string
      tags     = map(string)
    }
  ))
}