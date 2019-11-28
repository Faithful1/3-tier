provider "aws" {
  region                  = "ap-southeast-1"
  shared_credentials_file = "~/.aws/credentials"
}

module "vpc" {
  source          = "./vpc"
  vpc_cidr        = "10.0.0.0/16"
  public_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs   = ["10.0.3.0/24", "10.0.4.0/24"]
  transit_gateway = "${module.transit_gateway.transit_gateway}"
}

module "ec2" {
  source         = "./ec2"
  my_public_key  = "/tmp/id_rsa.pub"
  instance_type  = "t2.micro"
  security_group = "${module.vpc.security_group}"
  subnets        = "${module.vpc.public_subnets}"
}

module "alb" {
  source = "./alb"
  vpc_id = "${module.vpc.vpc_id}"

  subnet1 = "${module.vpc.subnet1}"

  subnet2 = "${module.vpc.subnet2}"
}

module "auto_scaling" {
  source           = "./auto_scaling"
  vpc_id           = "${module.vpc.vpc_id}"
  subnet1          = "${module.vpc.subnet1}"
  subnet2          = "${module.vpc.subnet2}"
  target_group_arn = "${module.alb.alb_target_group_arn}"
}

module "sns_topic" {
  source       = "./sns"
  alarms_email = "faithfulanere@gmail.com"
}

module "cloudwatch" {
  source      = "./cloudwatch"
  sns_topic   = "${module.sns_topic.sns_arn}"
  instance_id = "${module.ec2.instance_id}"
}

module "rds" {
  source      = "./rds"
  db_instance = "db.t2.micro"
  rds_subnet1 = "${module.vpc.private_subnet1}"
  rds_subnet2 = "${module.vpc.private_subnet2}"
  vpc_id      = "${module.vpc.vpc_id}"
}

module "route53" {
  source   = "./route53"
  hostname = ["test1", "test2"]
  arecord  = ["10.0.1.11", "10.0.1.12"]
  vpc_id   = "${module.vpc.vpc_id}"
}

module "iam" {
  source   = "./iam"
  username = ["faithful", "faithful", "faithful"]
}

