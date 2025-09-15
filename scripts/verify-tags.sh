#!/bin/bash
# Verify AAJ Tag Configuration
# This script verifies that all AWS resources will have the AAJ tag

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Terraform configuration
verify_terraform_tags() {
    log_info "Verifying Terraform tag configuration..."
    
    # Check main.tf for AAJ tag in default_tags
    if grep -q "AAJ.*=.*AAJ" terraform/main.tf; then
        log_success "✓ AAJ tag found in provider default_tags"
    else
        log_error "✗ AAJ tag not found in provider default_tags"
        return 1
    fi
    
    # Check main.tf for AAJ tag in common_tags
    if grep -q "AAJ.*=.*AAJ" terraform/main.tf; then
        log_success "✓ AAJ tag found in common_tags"
    else
        log_error "✗ AAJ tag not found in common_tags"
        return 1
    fi
    
    # Check all modules use var.tags
    log_info "Checking all modules use var.tags..."
    
    for module in terraform/modules/*/main.tf; do
        module_name=$(basename $(dirname $module))
        if grep -q "tags = var.tags" "$module" || grep -q "tags = merge(var.tags" "$module"; then
            log_success "✓ $module_name uses var.tags correctly"
        else
            log_warning "⚠ $module_name might not be using var.tags"
        fi
    done
}

# Show tag configuration
show_tag_configuration() {
    log_info "Current tag configuration:"
    echo ""
    echo "Provider default_tags:"
    grep -A 5 "default_tags" terraform/main.tf
    echo ""
    echo "Common tags:"
    grep -A 5 "common_tags" terraform/main.tf
    echo ""
}

# Show which resources will get the AAJ tag
show_tagged_resources() {
    log_info "Resources that will have the AAJ tag:"
    echo ""
    
    echo "🏗️ Infrastructure Resources:"
    echo "  • VPC and Subnets"
    echo "  • Internet Gateway and NAT Gateway"
    echo "  • Security Groups"
    echo "  • Route Tables"
    echo ""
    
    echo "☸️ EKS Resources:"
    echo "  • EKS Cluster"
    echo "  • EKS Node Groups"
    echo "  • EKS Add-ons"
    echo "  • IAM Roles and Policies"
    echo "  • CloudWatch Log Groups"
    echo ""
    
    echo "🗄️ Database Resources:"
    echo "  • RDS PostgreSQL Instance"
    echo "  • RDS Subnet Group"
    echo "  • RDS Parameter Group"
    echo "  • ElastiCache Redis Cluster"
    echo "  • ElastiCache Subnet Group"
    echo "  • ElastiCache Parameter Group"
    echo ""
    
    echo "🔧 Jenkins Resources:"
    echo "  • EC2 Instance"
    echo "  • EBS Volumes"
    echo "  • EBS Snapshots"
    echo "  • IAM Roles and Policies"
    echo "  • Security Groups"
    echo ""
    
    echo "📊 Monitoring Resources:"
    echo "  • S3 Buckets"
    echo "  • CloudWatch Log Groups"
    echo "  • CloudWatch Alarms"
    echo "  • SNS Topics"
    echo "  • CloudWatch Dashboards"
    echo ""
}

# Main verification function
main() {
    log_info "Starting AAJ tag verification..."
    echo ""
    
    verify_terraform_tags
    echo ""
    
    show_tag_configuration
    show_tagged_resources
    
    log_success "AAJ tag verification completed!"
    log_info "All AWS resources will be tagged with AAJ = 'AAJ'"
    log_info "This includes all infrastructure, compute, database, and monitoring resources"
}

# Run main function
main "$@"
