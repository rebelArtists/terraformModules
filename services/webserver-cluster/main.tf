provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "${var.db_remote_state_bucket}"
    key = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars = {
    server_port = "${var.server_port}"
    db_address = "${data.terraform_remote_state.db.outputs.address}"
    db_port = "${data.terraform_remote_state.db.outputs.port}"
    server_text = "${var.server_text}"
  }
}

# Declare the data source
data "aws_availability_zones" "all" {}

resource "aws_autoscaling_group" "example" {
  name = "${aws_launch_configuration.example.name}-cluster"
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = "${data.aws_availability_zones.all.names}"

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  min_elb_capacity = "${var.min_size}"

  tag {
    key = "Name"
    value = "${var.cluster_name}-example"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.elb.id}"
  from_port = "${var.elb_port}"
  to_port = "${var.elb_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_test" {
  type = "ingress"
  security_group_id = "${aws_security_group.elb.id}"
  from_port = 12000
  to_port = 12000
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.elb.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_elb" "example" {
  name = "${var.cluster_name}-example"
  availability_zones = "${data.aws_availability_zones.all.names}"
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"

  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "example" {
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "scale_out_morning" {
  count = "${var.enable_autoscaling}"

  scheduled_action_name = "scale-out-morning"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"

  autoscaling_group_name = "${aws_autoscaling_group.example.name}"
}

resource "aws_autoscaling_schedule" "scale_in_night" {
  count = "${var.enable_autoscaling}"

  scheduled_action_name = "scale-in-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"

  autoscaling_group_name = "${aws_autoscaling_group.example.name}"
}
