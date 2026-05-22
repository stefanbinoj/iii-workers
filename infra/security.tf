resource "aws_security_group" "api_sg" {
  name        = "api-gateway"
  description = "API Gateway Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-api"
  }
}

resource "aws_security_group" "workers_sg" {
  name        = "workers"
  description = "Workers Security Group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-workers"
  }
}

resource "aws_security_group_rule" "api_rpc_from_workers" {
  type                     = "ingress"
  description              = "RPC from workers"
  from_port                = local.rpc_port
  to_port                  = local.rpc_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.workers_sg.id
  security_group_id        = aws_security_group.api_sg.id
}

resource "aws_security_group_rule" "workers_ssh_from_api" {
  type                     = "ingress"
  description              = "SSH from API VM"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_sg.id
  security_group_id        = aws_security_group.workers_sg.id
}

resource "aws_security_group_rule" "workers_rpc_from_api" {
  type                     = "ingress"
  description              = "RPC from API VM"
  from_port                = local.rpc_port
  to_port                  = local.rpc_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_sg.id
  security_group_id        = aws_security_group.workers_sg.id
}

resource "aws_security_group_rule" "workers_rpc_from_workers" {
  type              = "ingress"
  description       = "Worker-to-worker RPC"
  from_port         = local.rpc_port
  to_port           = local.rpc_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.workers_sg.id
}
