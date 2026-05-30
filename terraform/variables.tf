variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" { type = string }
variable "environment"  { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "libraryhub"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "use_custom_domain" {
  type    = bool
  default = false
}
