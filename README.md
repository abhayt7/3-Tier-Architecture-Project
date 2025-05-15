# 🏗️ 3-Tier Architecture Deployment on AWS using Terraform

## 📖 Project Description

This project demonstrates the provisioning of a **3-tier architecture** on **AWS Cloud** using **Terraform**. The setup includes automated deployment of resources across network, compute, database, and DNS layers. This architecture separates the **web (frontend)**, **application (backend)**, and **database (data storage)** tiers for better **scalability**, **resilience**, and **security**.

---

## 🧱 Architecture Overview

### 1️⃣ Presentation Tier (Web Layer)
- **EC2 Instances** (Auto Scaling)
- **Nginx Web Server**
- **Application Load Balancer (ALB)**
- **Hosted in Public Subnets**

### 2️⃣ Application Tier (Backend Layer)
- **EC2 Instances** (Auto Scaling)
- **Nginx Backend Services**
- **Hosted in Public Subnets (can be private for real-time apps)**

### 3️⃣ Data Tier (Database Layer)
- **Amazon RDS (MySQL)**
- **Hosted in Private Subnets**
- **Secured with Security Groups and DB Subnet Group**

---

## 🧰 Services & Resources Used

| Category      | AWS Services                                |
|---------------|---------------------------------------------|
| Networking    | VPC, Subnets, Route Tables, Internet Gateway |
| Compute       | EC2, Launch Configuration, Auto Scaling      |
| Load Balancing| Application Load Balancer (ALB)              |
| Database      | RDS MySQL, DB Subnet Group                   |
| DNS           | Route 53 Hosted Zone & Records               |
| Security      | Security Groups, IAM Roles                   |
| IaC Tool      | Terraform (with remote state in S3 + DynamoDB) |

---

## 📂 Terraform Structure

- `main.tf` – All core resources
- `variables.tf` – Input variables
- `outputs.tf` – Output values (e.g., ALB DNS)
- `dataprovider.tf` – AMI Data Source
- `backend` – S3 & DynamoDB backend config for remote state

---

## 🪜 How to Deploy

### 1. Clone the Repository
```bash
git clone https://github.com/<your-username>/aws-3tier-terraform.git
cd aws-3tier-terraform
Initialize Terraform
bash
Copy
Edit
terraform init
3. Review the Execution Plan
bash
Copy
Edit
terraform plan
4. Apply the Infrastructure
bash
Copy
Edit
terraform apply
🌐 DNS Setup (Route 53)
The project includes Route 53 records for:

web.example-1.com

app.example-1.com

⚠️ Note: Ensure you own and configure example-1.com in Route 53 or update with your domain name.

🛡️ Security
Web/App Security Group: Allows HTTP (80) and HTTPS (443) traffic from the internet.

DB Security Group: Only allows MySQL (3306) traffic from specific web/application subnets.

Private Subnets: Database is placed in private subnets to restrict direct public access.

🔍 Outputs
terraform
Copy
Edit
output "app_lb_dns_name" {
  value = aws_lb.app_lb.dns_name
}
Use this output to access the Application Load Balancer (ALB) endpoint after successful deployment.
