data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "api_vm" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.api_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data                   = file("${path.module}/user_data/api.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "api-gateway-vm"
  }
}

resource "aws_instance" "worker_1" {
  ami                    = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type          = var.inference_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.workers_sg.id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data/worker1-py.sh", {
    api_private_ip = aws_instance.api_vm.private_ip
    hf_token       = var.hf_token
  })
  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.inference_root_volume_size
    volume_type = "gp3"
  }

  depends_on = [aws_route_table_association.private_assoc]

  tags = {
    Name = "worker-1"
  }
}

resource "aws_instance" "worker_2" {
  ami                    = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.workers_sg.id]
  key_name               = var.key_name

  user_data = templatefile("${path.module}/user_data/worker2-node.sh", {
    api_private_ip = aws_instance.api_vm.private_ip
  })
  user_data_replace_on_change = true

  depends_on = [aws_route_table_association.private_assoc]

  tags = {
    Name = "worker-2"
  }
}
