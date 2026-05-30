variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "eb_sg_id" { type = string }
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "aws_region" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}