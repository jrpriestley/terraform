variable "name" {
  type = string
}

variable "records" {
  type = list(object(
    {
      name    = string
      type    = string
      ttl     = number
      records = list(string)
    }
  ))
}

variable "vpc" {
  type = string
}