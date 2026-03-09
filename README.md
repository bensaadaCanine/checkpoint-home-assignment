# DevOps Home Assignment – EKS Microservices System

## Architecture

Client → ALB → Microservice 1 → SQS → Microservice 2 → S3

Components:

- Amazon EKS
- AWS Load Balancer Controller (ALB)
- Amazon SQS
- Amazon S3
- AWS SSM Parameter Store
- Amazon ECR
- Terraform
- GitHub Actions

## Services

### Microservice 1
REST API receiving POST requests and publishing validated payloads to SQS.

### Microservice 2
Worker that polls SQS and uploads messages to S3.

## Deployment Steps

### 1. Deploy Infrastructure

cd terraform
terraform init
terraform apply

### 2. Configure kubectl

aws eks update-kubeconfig --region us-east-1 --name devops-exam-cluster

### 3. Deploy Kubernetes Resources

kubectl apply -f k8s/

### 4. Test API

curl -X POST http://<ALB-DNS>/publish -H "Content-Type: application/json" -d '{
"data": {
"email_subject": "Happy new year!",
"email_sender": "John doe",
"email_timestream": "1693561101",
"email_content": "Just want to say... Happy new year!!!"
},
"token": "SuperSecretToken123"
}'