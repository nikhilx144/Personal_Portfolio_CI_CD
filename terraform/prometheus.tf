# ------------------------------
# Prometheus EC2 Instance
# ------------------------------

resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Allow Prometheus UI and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
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
    Name = "Prometheus-SG"
  }
}

resource "aws_instance" "prometheus" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  security_groups        = [aws_security_group.prometheus_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    systemctl enable docker
    systemctl start docker

    # Run Prometheus container
    docker run -d --name prometheus -p 9090:9090 \
      -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus
  EOF

  tags = {
    Name = "Prometheus-EC2"
  }
}