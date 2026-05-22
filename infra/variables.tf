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
  description = "Optional AMI override. Defaults to the latest Ubuntu 24.04 LTS amd64 AMI in the selected region."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
}

variable "hf_token" {
  description = "Optional Hugging Face token for model downloads."
  type        = string
  default     = ""
  sensitive   = true
}
