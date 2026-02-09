# This module creates a launch template for the web tier of the application.
# It uses the latest Amazon Linux 2 AMI and installs Nginx on the instances.
# The launch template is configured to use the specified security group and key pair.


#-----------------------------------------------------------
#  fetch the latest Amazon Linux 2 AMI
#-----------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#-----------------------------------------------------------
#  create a launch template for the web tier
#-----------------------------------------------------------
resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  # image_id      = data.aws_ami.amazon_linux.id
  image_id      = "ami-00b9840037f2380a4" # hardcoded for testing, replace with data source in production 
                                          # amzon linux 2 doesn't work properly so hardcoding the image id for amazon linux 2023 which works fine
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.web_sg_id]

user_data = base64encode(<<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Web Tier is UP</h1>" | sudo tee /usr/share/nginx/html/index.html
EOF
)


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web-ec2"
    }
  }
}


#-----------------------------------------------------------
#  Auto Scaling Group for the web tier
#-----------------------------------------------------------
resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }
}

#-----------------------------------------------------------
#  scaling policy to scale out when CPU utilization exceeds 50% and scale in when it falls below 50%
# ASG still starts with desired_capacity = 2

# If CPU > 50% → ASG scales out

# If CPU < 50% → ASG scales in
#-----------------------------------------------------------
resource "aws_autoscaling_policy" "web_cpu_scaling_policy" {
  name                   = "web-cpu-target-tracking"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
