#------------------------------------------------------
#  App ASG
#------------------------------------------------------

#----------------------------------------------
#  fetch latest Amazon Linux 2 AMI
#----------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

#----------------------------------------------
#  Launch Template for App ASG
#----------------------------------------------
resource "aws_launch_template" "app_lt" {
  name_prefix = "app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_sg_id]

user_data = base64encode(file("${path.module}/scripts/app_user_data.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "app-ec2"
    }
  }
}

#----------------------------------------------
#  Auto Scaling Group for App
#----------------------------------------------

resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.app_target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300


  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-asg-instance"
    propagate_at_launch = true
  }
}

#----------------------------------------------
#  Auto Scaling Policy for App ASG
# ASG still starts with desired_capacity = 2

# If CPU > 50% → ASG scales out

# If CPU < 50% → ASG scales in
#----------------------------------------------
resource "aws_autoscaling_policy" "app_cpu_scaling_policy" {
  name                   = "app-cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
