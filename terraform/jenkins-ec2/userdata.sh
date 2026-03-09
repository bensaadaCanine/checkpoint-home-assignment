#!/bin/bash
set -ex

# -------------------------
# Update system
# -------------------------
yum update -y

# -------------------------
# Add Jenkins repo and key file
# -------------------------
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key
yum upgrade -y

# -------------------------
# Install Java
# -------------------------
yum install java-21-amazon-corretto -y

# -------------------------
# Install AWS CLI
# -------------------------
yum install -y awscli

# -------------------------
# Install Jenkins and enable it
# -------------------------
yum install jenkins -y
systemctl enable jenkins

# -------------------------
# Install Docker
# -------------------------
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
usermod -aG docker jenkins

# -------------------------
# Install kubectl
# -------------------------
curl -o /usr/local/bin/kubectl \
  https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.0/2023-07-05/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl

# -------------------------
# Install Helm
# -------------------------
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -------------------------
# Retrieve admin user password from SSM
# -------------------------
export JENKINS_ADMIN_PASSWORD=$(aws ssm get-parameter \
  --name "/jenkins/admin-password" \
  --with-decryption \
  --region eu-west-1 \
  --query Parameter.Value \
  --output text)

# -------------------------
# Create admin user with groovy script
# -------------------------

mkdir -p /var/lib/jenkins/init.groovy.d

cat <<EOF >/var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "${JENKINS_ADMIN_PASSWORD}")
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
EOF

chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d

# -------------------------
# Disable the setup wizard
# -------------------------
echo 'JENKINS_JAVA_OPTIONS="-Djenkins.install.runSetupWizard=false"' >>/etc/sysconfig/jenkins

# -------------------------
# Jenkins start
# -------------------------
systemctl start jenkins
