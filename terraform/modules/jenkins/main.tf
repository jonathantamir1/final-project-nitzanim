# Jenkins Module - EC2 Instance
# This module creates the Jenkins EC2 instance for CI/CD

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Jenkins
resource "aws_iam_role_policy" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "eks:*",
          "ecr:*",
          "s3:*",
          "secretsmanager:*",
          "ssm:*",
          "cloudwatch:*",
          "logs:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = var.tags
}

# EBS Volume for Jenkins Home
resource "aws_ebs_volume" "jenkins_home" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 100  # Cost optimization: smaller volume
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-home"
  })
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  vpc_security_group_ids = [var.jenkins_security_group_id]
  subnet_id             = var.public_subnets[0]
  iam_instance_profile  = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size = 20  # Cost optimization: smaller root volume
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    jenkins_home = "/var/lib/jenkins"
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins"
  })
}

# Attach EBS Volume
resource "aws_volume_attachment" "jenkins_home" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins_home.id
  instance_id = aws_instance.jenkins.id
}

# EBS Snapshot for Backup
resource "aws_ebs_snapshot" "jenkins_home" {
  volume_id = aws_ebs_volume.jenkins_home.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-jenkins-home-snapshot"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "/aws/ec2/jenkins/${var.project_name}-${var.environment}"
  retention_in_days = 7  # Cost optimization: minimal retention

  tags = var.tags
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
