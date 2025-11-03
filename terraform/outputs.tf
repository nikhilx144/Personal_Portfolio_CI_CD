output "ec2_public_ip" {
  description = "Public IP of the Personal Portfolio EC2 instance"
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

output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
  description = "Public IP of Grafana EC2 instance"
}

output "prometheus_public_ip" {
  value = aws_instance.prometheus.public_ip
  description = "Public IP of Prometheus EC2 instance"
}