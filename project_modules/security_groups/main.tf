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
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
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
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "app_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.app_ec2_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

#----------------------------------------------
# Security Group Rules - Database Servers
#----------------------------------------------

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_ec2_sg.id
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "db_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.db_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
