variable "eips" {
  type = list(object(
    {
      name = string
      tags = map(string)
    },
  ))
}