variable "cidr" {
  type        = string
  description = "The CIDR block to use for the virtual network, e.g., 10.10.0.0/16"
  #default     = "10.100.0.0/16"
}

variable "project_name" {
  type        = string
  description = "Project name; will be used in naming convention"
  #default     = "project"
}