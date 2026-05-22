locals {
  rpc_port = 49134
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "aws_region" {
  default = "ap-south-2"
}

variable "availability_zone" {
  default = "ap-south-2c"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "instance_type" {
  default = "t3.small"
}

variable "inference_instance_type" {
  default = "c7i-flex.large"
}

variable "inference_root_volume_size" {
  description = "Root EBS volume size in GiB for the Python inference worker."
  default     = 16
}

variable "ami_id" {
  description = "Ubuntu 24.04 LTS amd64 gp3 AMI for ap-south-2."
  type        = string
  default     = "ami-0fcad4d1dfad502e9"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
  default     = "alchemy-test-2"
}

variable "hf_token" {
  description = "Optional Hugging Face token for model downloads."
  type        = string
  default     = ""
  sensitive   = true
}
