data "aws_ec2_instance_type" "app" {
  instance_type = var.instance_type
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-${one(data.aws_ec2_instance_type.app.supported_architectures)}"]
  }

  filter {
    name   = "architecture"
    values = [one(data.aws_ec2_instance_type.app.supported_architectures)]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
