# Monitoring Module - Outputs
# This file defines the outputs for the monitoring module

output "s3_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_groups" {
  description = "CloudWatch log groups"
  value = {
    application   = aws_cloudwatch_log_group.application.name
    infrastructure = aws_cloudwatch_log_group.infrastructure.name
  }
}
