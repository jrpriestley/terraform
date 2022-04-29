variable "cidr" {
  type = string
}

variable "create_igw" {
  type    = bool
  default = true
}

variable "dns_hostnames" {
  type    = bool
  default = true
}

variable "dns_support" {
  type    = bool
  default = true
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}