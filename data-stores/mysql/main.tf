provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "${var.mysql_db_name}"
  username = "admin"
  password = "${var.db_password}"
}
