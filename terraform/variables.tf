# variable "region" {
#     description = "AWS Region"
#     default = "ap-south-2"
# }

# variable "ami_id" {
#     description = "ID of the AMI running on the EC2 Instance"
#     default = "ami-0256158c639f8fa6b"
# }

# variable "key_name" {
#     description = "EC2 Instance Key Pair Name"
#     default = "devops_key_pair"
# }

# variable "type" {
#     description = "EC2 Instance Type"
#     default = "t3.micro"
# }

# variable "ecr-repo-uri" {
#     description = "ECR Repo URI"
#     default = "661979762009.dkr.ecr.ap-south-2.amazonaws.com/devops_ci_cd_final_prac_6_clean"
# }

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
