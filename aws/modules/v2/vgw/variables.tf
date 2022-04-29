variable "bgp_asn" {
  type = number
}

variable "name" {
  type = string
}

variable "propagate_to" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "vpc" {
  type = string
}