#!/bin/bash
# Status Page Application - Setup Script
# This script sets up the development environment and prerequisites

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

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    log_error "Unsupported operating system: $OSTYPE"
    exit 1
fi

log_info "Setting up Status Page DevOps environment on $OS..."

# Install prerequisites
install_prerequisites() {
    log_info "Installing prerequisites..."
    
    if [[ "$OS" == "macos" ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Install tools
        log_info "Installing tools with Homebrew..."
        brew install awscli terraform kubectl docker git
        
    elif [[ "$OS" == "linux" ]]; then
        # Update package list
        sudo apt-get update
        
        # Install tools
        log_info "Installing tools with apt..."
        sudo apt-get install -y awscli terraform kubectl docker.io git curl wget
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        log_warning "Please log out and log back in for Docker group changes to take effect"
    fi
    
    log_success "Prerequisites installed successfully"
}

# Configure AWS CLI
configure_aws() {
    log_info "Configuring AWS CLI..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_info "AWS CLI not configured. Please run 'aws configure' and enter your credentials:"
        aws configure
    else
        log_success "AWS CLI already configured"
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating project directories..."
    
    mkdir -p logs
    mkdir -p backups
    mkdir -p local
    
    log_success "Directories created successfully"
}

# Set up Git hooks
setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    # Pre-commit hook for Terraform formatting
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for Terraform formatting

if [ -d "terraform" ]; then
    cd terraform
    terraform fmt -check -diff
    if [ $? -ne 0 ]; then
        echo "Terraform files are not formatted. Run 'terraform fmt' to fix."
        exit 1
    fi
    cd ..
fi
EOF
    
    chmod +x .git/hooks/pre-commit
    
    log_success "Git hooks configured successfully"
}

# Create local configuration files
create_local_config() {
    log_info "Creating local configuration files..."
    
    # Create terraform.tfvars from example
    if [ ! -f "terraform/terraform.tfvars" ]; then
        cp terraform/terraform.tfvars.example terraform/terraform.tfvars
        log_warning "Created terraform/terraform.tfvars from example. Please update the values."
    fi
    
    # Create .env file
    cat > .env << 'EOF'
# Status Page Application Environment Variables
export AWS_REGION=us-west-2
export PROJECT_NAME=status-page
export ENVIRONMENT=prod
export EKS_CLUSTER_NAME=status-page-prod-cluster
export ECR_REPOSITORY=status-page-app
EOF
    
    log_success "Local configuration files created"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check AWS CLI
    if aws --version &> /dev/null; then
        log_success "AWS CLI: $(aws --version)"
    else
        log_error "AWS CLI not found"
        exit 1
    fi
    
    # Check Terraform
    if terraform --version &> /dev/null; then
        log_success "Terraform: $(terraform --version | head -n1)"
    else
        log_error "Terraform not found"
        exit 1
    fi
    
    # Check kubectl
    if kubectl version --client &> /dev/null; then
        log_success "kubectl: $(kubectl version --client --short 2>/dev/null)"
    else
        log_error "kubectl not found"
        exit 1
    fi
    
    # Check Docker
    if docker --version &> /dev/null; then
        log_success "Docker: $(docker --version)"
    else
        log_error "Docker not found"
        exit 1
    fi
    
    # Check Git
    if git --version &> /dev/null; then
        log_success "Git: $(git --version)"
    else
        log_error "Git not found"
        exit 1
    fi
    
    log_success "All tools verified successfully"
}

# Main setup function
main() {
    log_info "Starting Status Page DevOps setup..."
    
    install_prerequisites
    configure_aws
    create_directories
    setup_git_hooks
    create_local_config
    verify_installation
    
    log_success "Setup completed successfully!"
    log_info "Next steps:"
    log_info "1. Update terraform/terraform.tfvars with your values"
    log_info "2. Run './scripts/deploy.sh' to deploy the infrastructure"
    log_info "3. Check the documentation in docs/ for more information"
}

# Run main function
main "$@"
