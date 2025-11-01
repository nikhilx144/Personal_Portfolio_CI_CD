# resource "aws_security_group" "test-sg" {
#     name = "test-sg"
#     description = "Security Group for the EC2 Instance"

#     ingress {
#         from_port = 80
#         to_port = 80
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     ingress {
#         from_port = 22
#         to_port = 22
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     tags = {
#         Name = "test-sg"
#     }
# }

# resource "aws_iam_role" "ec2-ecr-access-role" {
#     name = "ec2-ecr-access-role"
#     assume_role_policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [{
#             Action = "sts:AssumeRole"
#             Effect = "Allow"
#             Principal = {
#                 Service = "ec2.amazonaws.com"
#             }
#         }]
#     })
# }

# resource "aws_iam_role_policy_attachment" "ecr-read-policy" {
#     role = aws_iam_role.ec2-ecr-access-role.name
#     policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_role_policy_attachment" "ssm-attach" {
#     role = aws_iam_role.ec2-ecr-access-role.name
#     policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2-profile" {
#     name = "ec2-profile"
#     role = aws_iam_role.ec2-ecr-access-role.name
# }

# resource "aws_instance" "test-ec2" {
#     ami = var.ami_id
#     instance_type = var.type
#     vpc_security_group_ids = [ aws_security_group.test-sg.id ]
#     key_name = var.key_name
#     iam_instance_profile = aws_iam_instance_profile.ec2-profile.name

#     user_data = base64encode(<<-EOF
#         #!/bin/bash
#         yum update -y
#         yum install docker -y
#         # amazon-linux-extras install docker -y (doesnt work for amazon linux 2023, only works for amazon linux 2)
#         systemctl enable docker
#         systemctl start docker
#         usermod -a -G docker ec2-user
#         sleep 10

#         REGION=${var.region}
#         ECR_REPO_URI=${var.ecr-repo-uri}

#         aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
#         docker pull $ECR_REPO_URI:latest

#         if [ $(docker ps -q -f name=sample-webpage-prac-image) ]; then
#             docker stop sample-webpage-prac-image
#             docker rm sample-webpage-prac-image
#         fi

#         docker run -d --name sample-webpage-prac-image -p 80:80 $ECR_REPO_URI:latest
#     EOF
#     )

#     tags = {
#         Name = "test-ec2"
#     }
# }

# ------------------------------
# IAM Role for EC2 to Access ECR
# ------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole" 
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "web_sg" {
  name        = var.security_group_name
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
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
    Name = "jenkins-ec2-sg"
  }
}

# ------------------------------
# Latest Amazon Linux 2 AMI
# ------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# ------------------------------
# EC2 Instance
# ------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
  key_name                = var.key_name
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name
  security_groups         = [aws_security_group.web_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    # ------------------------------
    # 1. System Update + Docker Install
    # ------------------------------
    yum update -y
    amazon-linux-extras install docker -y

    # Enable Docker on boot
    systemctl enable docker
    systemctl start docker

    # Add ec2-user to Docker group
    usermod -a -G docker ec2-user

    # Wait for Docker to start
    sleep 10

    # ------------------------------
    # 2. ECR Login and Run App Container
    # ------------------------------
    REGION=${var.region}
    REPO=${var.ecr_repo_url}

    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO
    docker pull $REPO

    # Stop existing container if running
    if [ $(docker ps -q -f name=college-website) ]; then
      docker stop college-website
      docker rm college-website
    fi

    # Run container on port 80
    docker run -d --name college-website -p 80:80 $REPO

    # ------------------------------
    # 3. Install Prometheus Node Exporter
    # ------------------------------
    cd /opt
    wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
    tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
    cd node_exporter-1.8.2.linux-amd64

    # Start Node Exporter as a background process
    nohup ./node_exporter > /var/log/node_exporter.log 2>&1 &

    # ------------------------------
    # 4. Optional: Enable Node Exporter on reboot
    # ------------------------------
    cat <<EOT > /etc/systemd/system/node_exporter.service
    [Unit]
    Description=Prometheus Node Exporter
    After=network.target

    [Service]
    ExecStart=/opt/node_exporter-1.8.2.linux-amd64/node_exporter
    User=root

    [Install]
    WantedBy=default.target
    EOT

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
  EOF


  tags = {
    Name = "CollegeWebsite-EC2"
  }
}