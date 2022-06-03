variable "server_port" {
  description = "port for HTTP requests"
  default = 8080
}

variable "elb_port" {
  description = "port for ELB requests"
  default = 80
}

variable "cluster_name" {
  description = "name for cluster resources"
}

variable "db_remote_state_bucket" {
  description = "name of s3 bucket for db remote state"
}

variable "db_remote_state_key" {
  description = "s3 key for db remote state file"
}

variable "instance_type" {
  description = "ec2 instance type"
}

variable "min_size" {
  description = "minimum number of servers in cluster"
}

variable "max_size" {
  description = "max servers in cluster"
}

variable "enable_autoscaling" {
  description = "boolean to turn on / of autoscaling"
}

variable "server_text" {
  description = "server text to display"
  default = "hello, world"
}

variable "ami" {
  description = "ami to run cluster with"
  default = "ami-07ebfd5b3428b6f4d"
}

variable "aws_region" {
  description = "aws region to use"
}
