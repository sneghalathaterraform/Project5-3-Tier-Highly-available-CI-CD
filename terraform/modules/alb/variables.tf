variable "name"           { type = string }
variable "vpc_id"         { type = string }
variable "public_subnets" { type = list(string) }
variable "alb_sg_id"      { type = string }
variable "project_name"   { type = string }
variable "environment"    { type = string }
variable "target_port" {
  type    = number
  default = 80
}
variable "health_path" {
  type    = string
  default = "/health"
}
