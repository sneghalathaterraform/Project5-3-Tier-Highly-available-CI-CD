variable "project_name" { type = string }
variable "environment" { type = string }
variable "eb_cname" { type = string }
variable "eb_dns_name" { type = string }
variable "eb_zone_id" { type = string }
variable "ec2_alb_dns_name" { type = string }
variable "ec2_alb_zone_id" { type = string }
variable "domain_name" {
  type    = string
  default = ""
}
variable "use_custom_domain" {
  type    = bool
  default = false
}