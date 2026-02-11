#----------------------------------------------
# Security Group for EC2 Instances
#----------------------------------------------

#----------------------------------------------
      # Internet
      #   ↓ (80 / 443)
      # ALB
      #   ↓ (80)
      # Web EC2
      #   ↓ (8080)
      # Internal ALB
      #   ↓ (8080)
      # App EC2
      #   ↓ (5432)
      # Postgres DB
#----------------------------------------------


resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  tags = { Name = "alb-sg" }
}

resource "aws_security_group" "web_ec2_sg" {
  name   = "web-ec2-sg"
  vpc_id = var.vpc_id

  tags = { Name = "web-ec2-sg" }
}

resource "aws_security_group" "internal_alb_sg" {
  name   = "internal-alb-sg"
  vpc_id = var.vpc_id

  tags = { Name = "internal-alb-sg" }
}

resource "aws_security_group" "app_ec2_sg" {
  name   = "app-ec2-sg"
  vpc_id = var.vpc_id

  tags = { Name = "app-ec2-sg" }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  tags = { Name = "db-sg" }
}



#----------------------------------------------
# Security Group Rules - ALB
#----------------------------------------------
resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https_in" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "alb_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}


#----------------------------------------------
# Security Group Rules - Web Servers
#----------------------------------------------

resource "aws_security_group_rule" "web_http_in" {
  type              = "ingress"
  security_group_id = aws_security_group.web_ec2_sg.id

  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "web_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.web_ec2_sg.id

  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb_sg.id
}

#----------------------------------------------
# Security Group Rules - Internal ALB
#----------------------------------------------

resource "aws_security_group_rule" "internal_alb_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.internal_alb_sg.id
  source_security_group_id = aws_security_group.web_ec2_sg.id
}

resource "aws_security_group_rule" "internal_alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.internal_alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

#----------------------------------------------
# Security Group Rules - Application Servers
#----------------------------------------------
resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app_ec2_sg.id
  source_security_group_id = aws_security_group.internal_alb_sg.id

  from_port = var.app_port
  to_port   = var.app_port
  protocol  = "tcp"
}

resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  security_group_id        = aws_security_group.app_ec2_sg.id
  source_security_group_id = aws_security_group.db_sg.id

  from_port = var.db_port
  to_port   = var.db_port
  protocol  = "tcp"
}


#----------------------------------------------
# Security Group Rules - Database Servers
#----------------------------------------------
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_ec2_sg.id

  from_port = var.db_port
  to_port   = var.db_port
  protocol  = "tcp"
}



# just for reference, the code below is the original code I wrote before I split the security group and rules into separate resources,


# the latter code doesn't work because of circular dependency between security groups, 
# so I have to split the security group and rules into two separate resources, 
# and use the security group id as reference in rules instead of using security group resource directly in rules




# #----------------------------------------------
# # Security Group for Application Load Balancer
# #----------------------------------------------

# resource "aws_security_group" "alb_sg" {
#   name        = "alb_security_group"
#   description = "Security group for Application Load Balancer"
#   vpc_id      = var.vpc_id

#   ingress {
#     description      = "Allow HTTP traffic"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   ingress {
#     description      = "Allow HTTPS traffic"
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#   }

#   egress {
#     description      = "Allow all outbound traffic"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "alb_security_group"
#   }
# }

# #----------------------------------------------
# # Security Group for web Servers
# #----------------------------------------------
# resource "aws_security_group" "web_ec2_sg" {
#   name        = "web_servers_security_group"
#   description = "Security group for web servers"
#   vpc_id      = var.vpc_id

#   ingress {
#     description      = "Allow HTTP traffic"
#     from_port        = 80
#     to_port          = 80
#     protocol         = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   egress {
#     description      = "Allow all outbound traffic"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     security_groups = [ aws_security_group.app_ec2_sg.id ]
#   }

#   tags = {
#     Name = "web_servers_security_group"
#   }
# }

# #----------------------------------------------
# # Security Group for application Servers
# #----------------------------------------------
# resource "aws_security_group" "app_ec2_sg" {
#   name        = "app_servers_security_group"
#   description = "Security group for application servers"
#   vpc_id      = var.vpc_id

#   ingress {
#     description      = "Allow traffic from web servers"
#     from_port        = var.app_port
#     to_port          = var.app_port
#     protocol         = "tcp"
#     security_groups = [aws_security_group.web_ec2_sg.id]
#   }

#   egress {
#     description      = "Allow all outbound traffic"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     security_groups = [ aws_security_group.db_ec2_sg.id ]
#   }

#   tags = {
#     Name = "app_servers_security_group"
#   }

# }

# #----------------------------------------------
# # Security Group for database Servers
# #----------------------------------------------
# resource "aws_security_group" "db_sg" {
#   name        = "db_servers_security_group"
#   description = "Security group for database servers"
#   vpc_id      = var.vpc_id

#   ingress {
#     description      = "Allow traffic from application servers"
#     from_port        = var.db_port
#     to_port          = var.db_port
#     protocol         = "tcp"
#     security_groups = [aws_security_group.app_ec2_sg.id]
#   }

#     tags = {
#       "Name" = "db_servers_security_group"
#     }
# }



