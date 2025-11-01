# output "ec2-public-ip" {
#     description = "EC2 Instance Public IP"
#     value = aws_instance.test-ec2.public_ip
# }

# output "ec2-public-dns" {
#     description = "EC2 Instance Public DNS"
#     value = aws_instance.test-ec2.public_dns
# }

# output "ec2-instance-id" {
#     description = "EC2 Instance ID"
#     value = aws_instance.test-ec2.id
# }


output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "ec2_instance_id" {
  description = "Instance ID"
  value       = aws_instance.web.id
}
