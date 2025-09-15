# Jenkins Module - Outputs
# This file defines the outputs for the Jenkins module

output "instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP of the Jenkins instance"
  value       = aws_instance.jenkins.public_ip
}

output "private_ip" {
  description = "Private IP of the Jenkins instance"
  value       = aws_instance.jenkins.private_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "iam_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "ebs_volume_id" {
  description = "ID of the Jenkins home EBS volume"
  value       = aws_ebs_volume.jenkins_home.id
}
