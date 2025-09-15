#!/bin/bash
# Status Page Application - Deployment Script
# This script automates the deployment of the Status Page application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="status-page"
ENVIRONMENT="prod"
AWS_REGION="us-west-2"
EKS_CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
ECR_REPOSITORY="${PROJECT_NAME}-app"
ECR_REGISTRY="123456789012.dkr.ecr.${AWS_REGION}.amazonaws.com"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    command -v aws >/dev/null 2>&1 || { log_error "AWS CLI is required but not installed. Aborting."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed. Aborting."; exit 1; }
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed. Aborting."; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "Docker is required but not installed. Aborting."; exit 1; }
    
    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || { log_error "AWS credentials not configured. Aborting."; exit 1; }
    
    log_success "Prerequisites check passed"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get outputs
    EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
    ECR_REGISTRY=$(terraform output -raw ecr_registry)
    
    log_success "Infrastructure deployed successfully"
    cd ..
}

configure_kubectl() {
    log_info "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
    
    # Verify cluster access
    kubectl get nodes >/dev/null 2>&1 || { log_error "Failed to access EKS cluster. Aborting."; exit 1; }
    
    log_success "kubectl configured successfully"
}

build_and_push_image() {
    log_info "Building and pushing Docker image..."
    
    # Get ECR login token
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Build image
    log_info "Building Docker image..."
    docker build -t ${ECR_REPOSITORY}:latest -f docker/Dockerfile .
    
    # Tag image
    docker tag ${ECR_REPOSITORY}:latest ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
    
    # Push image
    log_info "Pushing Docker image to ECR..."
    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
    
    log_success "Docker image pushed successfully"
}

deploy_application() {
    log_info "Deploying application to EKS..."
    
    # Apply Kubernetes manifests
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secrets.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/ingress.yaml
    kubectl apply -f k8s/hpa.yaml
    kubectl apply -f k8s/pdb.yaml
    
    # Wait for deployment
    log_info "Waiting for deployment to complete..."
    kubectl rollout status deployment/status-page-app -n status-page --timeout=300s
    
    log_success "Application deployed successfully"
}

setup_monitoring() {
    log_info "Setting up monitoring..."
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Prometheus
    kubectl apply -f monitoring/prometheus-config.yaml
    
    # Deploy Grafana dashboard
    kubectl apply -f monitoring/grafana-dashboard.json
    
    log_success "Monitoring setup completed"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pods
    log_info "Checking pod status..."
    kubectl get pods -n status-page
    
    # Check services
    log_info "Checking service status..."
    kubectl get services -n status-page
    
    # Check ingress
    log_info "Checking ingress status..."
    kubectl get ingress -n status-page
    
    # Get application URL
    INGRESS_IP=$(kubectl get ingress status-page-ingress -n status-page -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$INGRESS_IP" ]; then
        log_success "Application is available at: http://${INGRESS_IP}"
    else
        log_warning "Ingress IP not available yet. Check with: kubectl get ingress -n status-page"
    fi
    
    log_success "Deployment verification completed"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Remove Terraform plan file
    rm -f terraform/tfplan
    
    # Remove local Docker images
    docker rmi ${ECR_REPOSITORY}:latest ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Main deployment function
main() {
    log_info "Starting Status Page Application deployment..."
    
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    build_and_push_image
    deploy_application
    setup_monitoring
    verify_deployment
    cleanup
    
    log_success "Deployment completed successfully!"
    log_info "Next steps:"
    log_info "1. Update DNS records to point to the ALB"
    log_info "2. Configure SSL certificate"
    log_info "3. Set up monitoring alerts"
    log_info "4. Configure backup policies"
}

# Run main function
main "$@"
