variable "active_active" {
  type = bool
}

variable "enable_bgp" {
  type = bool
}

variable "name" {
  type = string
}

variable "public_ip" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "sku" {
  type = string
}

variable "subnet" {
  type = string
}

variable "type" {
  type = string
}

variable "virtual_network" {
  type = string
}

variable "vpn_type" {
  type = string
}

variable "tags" {
  type = map(string)
}