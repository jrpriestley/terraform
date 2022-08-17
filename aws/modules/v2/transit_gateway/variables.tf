variable "auto_accept_shared_attachments" {
  type    = string
  default = "disable"
}

variable "amazon_side_asn" {
  type = string
}

variable "description" {
  type = string
}

variable "tags" {
  type = map(string)
}