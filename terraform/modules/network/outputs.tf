output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnets }
output "private_subnet_ids" { value = module.vpc.private_subnets }
output "ssm_vpc_endpoint_ids" { value = { for service, endpoint in aws_vpc_endpoint.ssm_interface : service => endpoint.id } }
output "s3_vpc_endpoint_id" { value = aws_vpc_endpoint.s3.id }
