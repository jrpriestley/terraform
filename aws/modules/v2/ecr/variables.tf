variable "name" {
  type        = string
  description = "Repository name"
}

variable "tags" {
  type = map(string)
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDR with public access to the repository"
}