variable "name" {
  type = string
}

variable "records" {
  type = map(object(
    {
      type    = string
      ttl     = number
      records = list(string)
    }
  ))
}

variable "vpc" {
  type = string
}