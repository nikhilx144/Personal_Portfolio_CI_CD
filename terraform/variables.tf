variable "region" {
  description = "AWS region to deploy resources"
  default     = "ap-south-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}


variable "key_name" {
  description = "Existing EC2 key pair name"
  default     = "devops_key_pair"
}

variable "ecr_repo_url" {
  description = "ECR repository URL of the Docker image"
  default     = "661979762009.dkr.ecr.ap-south-2.amazonaws.com/devops_ci_cd_final_prac_6_clean"
}

variable "security_group_name" {
  description = "Security group name for EC2 instance"
  default     = "jenkins-ec2-sg"
}
