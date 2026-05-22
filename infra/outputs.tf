output "api_public_ip" {
  value = aws_instance.api_vm.public_ip
}

output "worker_1_private_ip" {
  value = aws_instance.worker_1.private_ip
}

output "worker_2_private_ip" {
  value = aws_instance.worker_2.private_ip
}
