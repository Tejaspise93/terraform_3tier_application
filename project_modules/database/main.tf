#-------------------------------------------
# Database Subnet Group
#-------------------------------------------

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "postgres-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "postgres-subnet-group"
  }
}

#-------------------------------------------
# RDS Instance for PostgreSQL
#-------------------------------------------
resource "aws_db_instance" "postgres" {
  identifier              = "postgres-db"
  engine                  = "postgres"
  engine_version          = "17.6"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"

  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [var.db_sg_id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false

  tags = {
    Name = "postgres-db"
  }
}
