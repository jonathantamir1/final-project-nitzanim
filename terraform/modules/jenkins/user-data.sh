#!/bin/bash
# Jenkins User Data Script
# This script installs and configures Jenkins on Ubuntu

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add jenkins user to docker group
usermod -aG docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y jenkins

# Configure Jenkins
JENKINS_HOME="${jenkins_home}"
mkdir -p $JENKINS_HOME
chown jenkins:jenkins $JENKINS_HOME

# Create Jenkins configuration directory
mkdir -p /etc/jenkins
chown jenkins:jenkins /etc/jenkins

# Configure Jenkins to use the EBS volume
echo "JENKINS_HOME=$JENKINS_HOME" >> /etc/default/jenkins

# Start Jenkins
systemctl start jenkins
systemctl enable jenkins

# Install required Jenkins plugins
sleep 30  # Wait for Jenkins to start
JENKINS_URL="http://localhost:8080"
JENKINS_CLI_JAR="/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar"

# Wait for Jenkins to be ready
while ! curl -f $JENKINS_URL > /dev/null 2>&1; do
    echo "Waiting for Jenkins to start..."
    sleep 10
done

# Download Jenkins CLI
wget -O $JENKINS_CLI_JAR $JENKINS_URL/jnlpJars/jenkins-cli.jar

# Install plugins
java -jar $JENKINS_CLI_JAR -s $JENKINS_URL install-plugin \
    workflow-aggregator \
    git \
    docker-workflow \
    kubernetes \
    aws-credentials \
    aws-ecr \
    aws-eks \
    pipeline-stage-view \
    build-timeout \
    credentials-binding \
    timestamper \
    ws-cleanup \
    ant \
    gradle \
    ssh-slaves \
    matrix-auth \
    pam-auth \
    ldap \
    email-ext \
    mailer \
    slack \
    blueocean

# Restart Jenkins
systemctl restart jenkins

# Create Jenkins jobs directory
mkdir -p $JENKINS_HOME/jobs
chown jenkins:jenkins $JENKINS_HOME/jobs

# Configure AWS CLI for Jenkins user
sudo -u jenkins aws configure set region us-west-2

# Create backup script
cat > /usr/local/bin/backup-jenkins.sh << 'EOF'
#!/bin/bash
# Backup Jenkins home directory to S3
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/tmp/jenkins-backup-${BACKUP_DATE}.tar.gz"
S3_BUCKET="status-page-backups"

# Create backup
tar -czf $BACKUP_FILE -C /var/lib/jenkins .

# Upload to S3
aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/jenkins/

# Cleanup
rm $BACKUP_FILE

echo "Jenkins backup completed: $BACKUP_FILE"
EOF

chmod +x /usr/local/bin/backup-jenkins.sh

# Schedule daily backup
echo "0 2 * * * /usr/local/bin/backup-jenkins.sh" | crontab -u jenkins -

# Log completion
echo "Jenkins installation completed successfully" >> /var/log/jenkins-install.log
