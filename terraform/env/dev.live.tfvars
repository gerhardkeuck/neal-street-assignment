vpc_cidr             = "10.60.0.0/16"
public_subnet_cidrs  = ["10.60.1.0/24"]
private_subnet_cidrs = ["10.60.2.0/24"]

instance_type    = "t4g.nano"
desired_capacity = 2
min_size         = 1
max_size         = 3
