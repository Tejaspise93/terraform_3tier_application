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
# Fetch latest PostgreSQL engine version
#-------------------------------------------
data "aws_rds_engine_version" "postgres" {
  engine             = "postgres"
  preferred_versions = ["17.6", "17.5", "17.4", "16.4", "16.3"]
}

#-------------------------------------------
# RDS Instance for PostgreSQL
#-------------------------------------------
resource "aws_db_instance" "postgres" {
  identifier              = "postgres-db"
  engine                  = "postgres"
  engine_version          = data.aws_rds_engine_version.postgres.version
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
