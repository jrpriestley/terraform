variable "clusters" {
  type        = list(string)
  description = "Clusters to provide access to"
}

variable "name" {
  type        = string
  description = "Registry name"
}

variable "resource_group" {
  type        = string
  description = "Resource group to provision into"
}

variable "sku" {
  type        = string
  description = "Registry SKU"
}

variable "tags" {
  type = map(string)
}