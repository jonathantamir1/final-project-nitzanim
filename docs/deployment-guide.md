# Status Page Application - Deployment Guide

## 🚀 Quick Start

### Prerequisites

Before deploying the Status Page application, ensure you have the following tools installed:

- **AWS CLI** (v2.0+)
- **Terraform** (v1.0+)
- **kubectl** (v1.28+)
- **Docker** (v20.0+)
- **Git** (v2.0+)

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/status-page-devops.git
cd status-page-devops
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (us-west-2)
```

### 3. Deploy Infrastructure

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Run the deployment script
./scripts/deploy.sh
```

### 4. Access the Application

After deployment, the application will be available at:
- **Status Page**: `http://your-alb-ip`
- **Jenkins**: `http://jenkins-ip:8080`
- **Grafana**: `http://grafana-ip:3000`

## 📋 Detailed Deployment Steps

### Step 1: Infrastructure Setup

The deployment script will:

1. **Create VPC and Networking**
   - VPC with public and private subnets
   - Internet Gateway and NAT Gateway
   - Security Groups with restrictive rules

2. **Deploy EKS Cluster**
   - Kubernetes cluster with managed node groups
   - System nodes for critical workloads
   - Application nodes for the Status Page app
   - Spot nodes for cost optimization

3. **Set up Databases**
   - RDS PostgreSQL instance (Multi-AZ)
   - ElastiCache Redis cluster (Multi-AZ)

4. **Deploy Jenkins**
   - EC2 instance with Jenkins pre-configured
   - Docker and kubectl installed
   - IAM roles for AWS access

### Step 2: Application Deployment

1. **Build Docker Image**
   - Multi-stage Dockerfile for optimization
   - Security scanning and testing
   - Push to Amazon ECR

2. **Deploy to Kubernetes**
   - Namespace and ConfigMaps
   - Secrets and Deployments
   - Services and Ingress
   - Horizontal Pod Autoscaler

3. **Configure Monitoring**
   - Prometheus for metrics collection
   - Grafana for visualization
   - CloudWatch for AWS metrics

### Step 3: Post-Deployment Configuration

1. **Update DNS Records**
   ```bash
   # Get the ALB DNS name
   kubectl get ingress status-page-ingress -n status-page
   
   # Update your DNS to point to the ALB
   ```

2. **Configure SSL Certificate**
   ```bash
   # Update the certificate ARN in k8s/ingress.yaml
   # Replace 'your-cert-id' with your actual certificate ID
   ```

3. **Set up Monitoring Alerts**
   ```bash
   # Configure SNS topics for alerts
   # Update email addresses in Terraform configuration
   ```

## 🔧 Configuration

### Environment Variables

The application uses the following environment variables:

```yaml
# Database Configuration
DATABASE_NAME: "statuspage"
DATABASE_USER: "statuspage"
DATABASE_HOST: "your-rds-endpoint"
DATABASE_PORT: "5432"

# Redis Configuration
REDIS_HOST: "your-redis-endpoint"
REDIS_PORT: "6379"
REDIS_DB: "0"

# Security
SECRET_KEY: "your-secret-key"
ALLOWED_HOSTS: "your-domain.com"

# Email Configuration
EMAIL_HOST: "smtp.gmail.com"
EMAIL_PORT: "587"
EMAIL_USE_TLS: "True"
```

### Kubernetes Configuration

#### Namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: status-page
```

#### ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: status-page-config
  namespace: status-page
data:
  DEBUG: "False"
  ALLOWED_HOSTS: "status.yourdomain.com"
  # ... other configuration
```

#### Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: status-page-secrets
  namespace: status-page
type: Opaque
data:
  SECRET_KEY: "base64-encoded-secret"
  DATABASE_PASSWORD: "base64-encoded-password"
  # ... other secrets
```

## 📊 Monitoring Setup

### Prometheus Configuration

Prometheus is configured to scrape metrics from:
- Kubernetes pods and services
- Application endpoints
- Node metrics
- Custom application metrics

### Grafana Dashboards

The deployment includes pre-configured dashboards for:
- Application health and performance
- Infrastructure metrics
- Error rates and response times
- Resource utilization

### CloudWatch Integration

- Application logs are sent to CloudWatch
- Custom metrics are published to CloudWatch
- Alarms are configured for critical thresholds

## 🔒 Security Configuration

### Network Security

- **VPC**: Isolated network environment
- **Security Groups**: Restrictive firewall rules
- **WAF**: Web application firewall (optional)

### Data Security

- **Encryption at Rest**: All data encrypted with KMS
- **Encryption in Transit**: TLS 1.3 for all communications
- **Secrets Management**: AWS Secrets Manager

### Access Control

- **IAM Roles**: Least privilege access
- **RBAC**: Kubernetes role-based access control
- **Multi-Factor Authentication**: Required for admin access

## 💰 Cost Optimization

### Infrastructure Optimizations

- **Spot Instances**: 50-70% savings on non-critical workloads
- **Single NAT Gateway**: Reduced networking costs
- **Minimal Instance Sizes**: db.t3.micro, cache.t3.micro
- **Auto Scaling**: Scale down during low usage

### Storage Optimizations

- **S3 Lifecycle**: Move old logs to cheaper storage
- **EBS Optimization**: Use GP3 for better price/performance
- **Backup Retention**: Minimal retention periods

### Monitoring Optimizations

- **Basic CloudWatch**: Disabled detailed monitoring
- **Minimal Log Retention**: 7 days for most logs
- **Efficient Metrics**: Only essential metrics collected

## 🚨 Troubleshooting

### Common Issues

1. **Pod Startup Failures**
   ```bash
   kubectl describe pod <pod-name> -n status-page
   kubectl logs <pod-name> -n status-page
   ```

2. **Database Connection Issues**
   ```bash
   kubectl exec -it <pod-name> -n status-page -- python manage.py dbshell
   ```

3. **Ingress Not Working**
   ```bash
   kubectl get ingress -n status-page
   kubectl describe ingress status-page-ingress -n status-page
   ```

4. **Jenkins Connection Issues**
   ```bash
   # Check Jenkins logs
   sudo journalctl -u jenkins -f
   
   # Check Jenkins status
   sudo systemctl status jenkins
   ```

### Log Locations

- **Application Logs**: `kubectl logs -n status-page`
- **Jenkins Logs**: `/var/log/jenkins/jenkins.log`
- **CloudWatch Logs**: `/aws/eks/status-page-prod/application`

### Health Checks

```bash
# Check application health
curl http://your-alb-ip/health/

# Check Kubernetes cluster
kubectl get nodes
kubectl get pods -n status-page

# Check database connectivity
kubectl exec -it <pod-name> -n status-page -- python manage.py check --database default
```

## 🔄 Updates and Maintenance

### Application Updates

1. **Code Changes**
   ```bash
   git push origin main
   # Jenkins will automatically build and deploy
   ```

2. **Manual Deployment**
   ```bash
   kubectl set image deployment/status-page-app status-page=your-image:tag -n status-page
   kubectl rollout status deployment/status-page-app -n status-page
   ```

### Infrastructure Updates

1. **Terraform Changes**
   ```bash
   cd terraform
   terraform plan
   terraform apply
   ```

2. **Kubernetes Updates**
   ```bash
   kubectl apply -f k8s/
   ```

### Backup and Recovery

1. **Database Backup**
   ```bash
   # RDS automated backups are enabled
   # Manual backup
   aws rds create-db-snapshot --db-instance-identifier your-db-id --db-snapshot-identifier manual-backup-$(date +%Y%m%d)
   ```

2. **Jenkins Backup**
   ```bash
   # Automated daily backups to S3
   # Manual backup
   sudo /usr/local/bin/backup-jenkins.sh
   ```

## 📞 Support

For issues and questions:

1. **Check the logs** using the troubleshooting section
2. **Review the documentation** in the `docs/` directory
3. **Create an issue** in the GitHub repository
4. **Contact the DevOps team** for critical issues

## 🔗 Useful Links

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
