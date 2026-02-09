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
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#----------------------------------------------
#  Launch Template for App ASG
#----------------------------------------------
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  # image_id      = data.aws_ami.amazon_linux.id
  image_id      = "ami-00b9840037f2380a4" # hardcoded for testing, replace with data source in production 
                                          # amzon linux 2 doesn't work properly so hardcoding the image id for amazon linux 2023 which works fine
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_sg_id]

user_data = base64encode(<<-EOF
#!/bin/bash
sudo yum update -y

# Install Python
sudo yum install -y python3

# Create a simple app directory
sudo mkdir -p /opt/app
sudo chown ec2-user:ec2-user /opt/app

# Create a simple index file
echo "Hello from App Tier on port 8080" | sudo tee /opt/app/index.html

# Start a simple HTTP server on port 8080
cd /opt/app
sudo nohup python3 -m http.server 8080 > /var/log/app.log 2>&1 &
EOF
)


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
  name                = "app-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = var.private_subnet_ids

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
