module "network" {
  source = "../modules/network"

  name_prefix          = local.name_prefix
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
module "security" {
  source = "../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  vpc_cidr    = var.vpc_cidr
  app_port    = var.app_port
}

module "iam" {
  source = "../modules/iam"

  name_prefix              = local.name_prefix
  app_secret_name_prefix   = local.secret_name_prefix
  github_actions_role_name = local.github_actions_role_name
  ansible_ssm_bucket_name  = aws_s3_bucket.ansible_ssm.id
}

module "loadbalancer" {
  source            = "../modules/loadbalancer"
  name_prefix       = local.name_prefix
  public_subnet_ids = module.network.public_subnet_ids
  app_port          = var.app_port
  health_path       = var.health_path
  vpc_id            = module.network.vpc_id
}

module "compute" {
  source = "../modules/compute"

  name_prefix           = local.name_prefix
  service               = var.service
  environment           = local.environment
  subnet_ids            = module.network.private_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  target_group_arn      = module.loadbalancer.target_group_arn
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.instance_type
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
}

module "observability" {
  source = "../modules/observability"

  name_prefix             = local.name_prefix
  nlb_arn_suffix          = module.loadbalancer.nlb_arn_suffix
  target_group_arn_suffix = module.loadbalancer.target_group_arn_suffix
  asg_name                = module.compute.asg_name
  alarm_email             = var.alarm_email
}
