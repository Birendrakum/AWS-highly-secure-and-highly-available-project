# AWS Highly Secure and Highly Available Infrastructure using Terraform

## 📖 Overview

This project provisions a **highly available**, **secure**, and **scalable** web application infrastructure on AWS using **Terraform**. It demonstrates Infrastructure as Code (IaC) principles while incorporating AWS best practices for networking, security, monitoring, and fault tolerance.

The architecture is designed to minimize downtime, improve resilience, and protect workloads using multiple AWS security services.

---

# 🏗️ Architecture

```
                        Internet
                            │
                            │
                   ┌─────────────────┐
                   │ Application Load│
                   │    Balancer     │
                   └────────┬────────┘
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
   EC2 Instance (AZ-1)                 EC2 Instance (AZ-2)
      Auto Scaling                        Auto Scaling
          │                                   │
          └─────────────────┬─────────────────┘
                            │
                  Private Subnets (Multi-AZ)
                            │
                ┌───────────┴───────────┐
                │                       │
         NAT Gateway             Internet Gateway
                │
        Outbound Internet Access

Additional Security & Monitoring:
- AWS WAF
- Amazon GuardDuty
- VPC Flow Logs
- CloudWatch Logs & Metrics
- S3 Buckets
- IAM Roles & Policies
```

---

# ✨ Features

* Infrastructure provisioned using Terraform
* Multi-AZ deployment for high availability
* Public and private subnet architecture
* Application Load Balancer (ALB)
* EC2 Auto Scaling Group
* Launch Template for EC2 instances
* Internet Gateway and NAT Gateway
* Security Groups with least-privilege rules
* AWS WAF integration for web protection
* Amazon GuardDuty for threat detection
* VPC Flow Logs for network monitoring
* CloudWatch monitoring and logging
* S3 bucket integration for storage and logging
* IAM roles and policies for secure access management

---

# 🛠️ AWS Services Used

* Amazon VPC
* EC2
* Auto Scaling Group
* Launch Template
* Application Load Balancer (ALB)
* Internet Gateway
* NAT Gateway
* Security Groups
* IAM
* Amazon S3
* Amazon CloudWatch
* AWS WAF
* Amazon GuardDuty
* VPC Flow Logs

---

# 📂 Project Structure

```
.
├── provider.tf
├── Network_Infra.tf
├── Webapp_Infra.tf
├── Monitoring_and_Logging.tf
├── bucket.tf
├── data_source.tf
├── lambda.tf
├── Notification.tf
├── lambda_health_function.py
├── lambda_Incident_function.py
├── lambda_function.zip
└── README.md
```

---

# 🚀 Deployment

## Prerequisites

* Terraform installed
* AWS CLI configured
* AWS account with appropriate permissions

## Initialize Terraform

```bash
terraform init
```

## Review the execution plan

```bash
terraform plan
```

## Deploy the infrastructure

```bash
terraform apply
```

## Destroy the infrastructure

```bash
terraform destroy
```

---

# 🔒 Security Best Practices Implemented

* Network isolation using public and private subnets
* Security Groups configured with restricted inbound access
* Traffic routed through an Application Load Balancer
* Threat detection with Amazon GuardDuty
* Web application protection using AWS WAF
* Network activity captured using VPC Flow Logs
* Monitoring through CloudWatch
* IAM-based access control following least-privilege principles

---

# 📈 High Availability Design

* Resources distributed across multiple Availability Zones
* Auto Scaling Group automatically replaces unhealthy instances
* Application Load Balancer distributes incoming traffic
* Private subnets reduce direct exposure of application servers
* NAT Gateway enables secure outbound internet access for private resources

---

# 💡 Future Improvements

* Store Terraform state remotely in an S3 bucket with DynamoDB state locking
* Add HTTPS support with AWS Certificate Manager (ACM)
* Integrate Amazon RDS Multi-AZ deployment
* Use Terraform modules for improved reusability
* Add CI/CD using GitHub Actions or AWS CodePipeline
* Enable automated backups and disaster recovery workflows

---

# 🎯 Skills Demonstrated

* Terraform Infrastructure as Code (IaC)
* AWS Networking
* High Availability Architecture
* Cloud Security
* Auto Scaling
* Load Balancing
* Monitoring & Logging
* IAM and Access Management
* DevOps Best Practices

---

# 👨‍💻 Author

**Birendra Kumar**

Aspiring Cloud & DevOps Engineer with hands-on experience in AWS, Terraform, Docker, Kubernetes, Linux, and automation projects.
