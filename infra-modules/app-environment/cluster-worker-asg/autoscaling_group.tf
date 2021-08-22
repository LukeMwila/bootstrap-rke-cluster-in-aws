data "aws_ami" "openSUSE" {
  most_recent = true

  filter {
    name   = "name"
    values = ["openSUSE-Leap-15-2-v20200702-hvm-ssd-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

# EC2 Auto Scaling Group - Launch Template
resource "aws_launch_template" "launch_template" {
  name_prefix   = var.name_prefix
  image_id      = data.aws_ami.openSUSE.id
  instance_type = var.ec2_instance_type

  vpc_security_group_ids = var.launch_template_security_group_ids

  user_data = filebase64("${path.module}/${var.user_data}")
  key_name = var.key_name 

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.launch_template_tag
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  }
}

# EC2 Auto Scaling Group Worker Nodes
resource "aws_autoscaling_group" "asg" {
  availability_zones = var.availability_zones
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  force_delete       = true
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  /* lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  } */

  tag {
    key                 = "InstanceType"
    value               = var.asg_tag
    propagate_at_launch = true
  }
}