module "network" {
  source                  = "./project_modules/network"
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr      = var.public_subnet_cidr_list
  app_private_subnet_cidr = var.app_private_subnet_cidr_list
  db_private_subnet_cidr  = var.db_private_subnet_cidr_list
  availability_zone       = var.availability_zone_list
}

module "sg" {
  source = "./project_modules/security_groups"
  vpc_id = module.network.vpc_id
}

module "alb" {
  source            = "./project_modules/alb"
  public_subnet_ids = module.network.public_subnet_ids
  vpc_id            = module.network.vpc_id
  alb_sg_id         = module.sg.alb_sg_id
  name              = var.alb_name
}

module "web_asg" {
  source = "./project_modules/web_asg"

  public_subnet_ids = module.network.public_subnet_ids
  web_sg_id         = module.sg.web_ec2_sg_id
  target_group_arn  = module.alb.target_group_arn
  instance_type     = var.instance_type
}

module "app_asg" {
  source = "./project_modules/app_asg"

  private_subnet_ids = module.network.app_private_subnet_ids
  app_sg_id          = module.sg.app_ec2_sg_id
  instance_type      = var.instance_type
}

module "database" {
  source = "./project_modules/database"

  db_subnet_ids     = module.network.db_private_subnet_ids
  db_sg_id          = module.sg.db_sg_id
  db_instance_class = var.db_instance_class

  #-------------------- Sensitive Variables ------------------
  # will use secrets manager to securely manage sensitive data in production environment, 
  # for demonstration purposes we are defining a default value here, but in a real-world scenario,
  # you should remove the default value and provide it securely during deployment.
  # change afterwards
  #-------------------- Sensitive Variables ------------------
  db_password = var.db_password

}

