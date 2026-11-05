# Design Document

## Overview

This document presents the architectural design for deploying Capi's Rentals hash service to AWS. The design balances simplicity, cost-effectiveness, and reliability for a WorldSkills Cloud Computing competition scenario within AWS Learner Lab constraints.

The architecture follows a three-tier pattern: Network (VPC), Compute (EC2 + ASG), and Data (DynamoDB). All components are designed for manual deployment via AWS Console, with step-by-step instructions in Portuguese for beginner users.

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                        │
│                                  │                                           │
│                                  ▼                                           │
│                    ┌─────────────────────────┐                              │
│                    │   Internet Gateway      │                              │
│                    │      (IGW)              │                              │
│                    └────────────┬────────────┘                              │
│                                 │                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐    │
│  │                         VPC (10.0.0.0/16)                            │    │
│  │  ┌────────────────────────────┐  ┌────────────────────────────┐       │    │
│  │  │   Public Subnet AZ-a       │  │   Public Subnet AZ-b       │       │    │
│  │  │   (10.0.1.0/24)           │  │   (10.0.2.0/24)           │       │    │
│  │  │                            │  │                            │       │    │
│  │  │  ┌──────────────────┐     │  │     ┌──────────────────┐  │       │    │
│  │  │  │  EC2 Instance    │     │  │     │  EC2 Instance    │  │       │    │
│  │  │  │  (t3.micro)      │     │  │     │  (t3.micro)      │  │       │    │
│  │  │  │  ┌────────────┐  │     │  │     │  ┌────────────┐  │  │       │    │
│  │  │  │  │ Go Server  │  │     │  │     │  │ Go Server  │  │  │       │    │
│  │  │  │  │ Port 80    │  │     │  │     │  │ Port 80    │  │  │       │    │
│  │  │  │  └────────────┘  │     │  │     │  └────────────┘  │  │       │    │
│  │  │  └────────┬─────────┘     │  │     └────────┬─────────┘  │       │    │
│  │  │           │               │  │              │            │       │    │
│  │  └───────────┼───────────────┘  └──────────────┼────────────┘       │    │
│  │              │                                  │                    │    │
│  │              └──────────────┬──────────────────┘                    │    │
│  │                             │                                         │    │
│  │              ┌──────────────▼──────────────┐                         │    │
│  │              │   Application Load Balancer │                         │    │
│  │              │         (ALB)               │                         │    │
│  │              │     Listener: Port 80       │                         │    │
│  │              │     Health: /health         │                         │    │
│  │              └──────────────┬──────────────┘                         │    │
│  │                             │                                         │    │
│  │              ┌──────────────▼──────────────┐                         │    │
│  │              │      Target Group            │                         │    │
│  │              │   (EC2 instances pool)       │                         │    │
│  │              └──────────────────────────────┘                         │    │
│  │                                                                       │    │
│  │              ┌─────────────────────────────────────────────────┐      │    │
│  │              │           Auto Scaling Group (ASG)              │      │    │
│  │              │   Min: 1 | Max: 3 | Desired: 1                  │      │    │
│  │              │   Health Checks: ELB                            │      │    │
│  │              │   Scaling Policies: CPU-based                   │      │    │
│  │              └─────────────────────────────────────────────────┘      │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
│                                 │                                            │
│                    ┌────────────▼────────────┐                               │
│                    │      DynamoDB           │                               │
│                    │  Table: CapiRentalsHash │                               │
│                    │  Key: id (String)       │                               │
│                    │  Mode: On-Demand        │                               │
│                    └─────────────────────────┘                               │
│                                                                               │
│                    ┌─────────────────────────┐                               │
│                    │     CloudWatch          │                               │
│                    │  - CPU Metrics          │                               │
│                    │  - ALB Metrics          │                               │
│                    │  - Alarms (CPU > 80%)   │                               │
│                    └─────────────────────────┘                               │
└─────────────────────────────────────────────────────────────────────────────┘

                            ┌─────────────────┐
                            │    IAM Role     │
                            │  - DynamoDB     │
                            │    PutItem      │
                            │  - CloudWatch   │
                            │    Metrics      │
                            └─────────────────┘
```

### Component Interaction Flow

```
User Request Flow:
══════════════════

1. HTTP Request (http://alb-dns-name/calc?input=text)
   │
   ▼
2. Internet Gateway → Route to ALB
   │
   ▼
3. Application Load Balancer
   ├── Listener receives HTTP on port 80
   ├── Routes to Target Group
   └── Health check verifies instance health
   │
   ▼
4. Target Group selects healthy EC2 instance
   │
   ▼
5. EC2 Instance (Go Application)
   ├── Receives request on port 80
   ├── Validates input parameter
   ├── Computes SHA256 hash
   ├── Persists to DynamoDB via IAM role
   └── Returns JSON response
   │
   ▼
6. Response travels back: EC2 → ALB → IGW → User


Auto Scaling Flow:
══════════════════

1. CloudWatch monitors EC2 CPU utilization
   │
   ▼
2. CPU > 70% for 5 minutes?
   ├── YES → Scale-out alarm triggers
   │         └── ASG launches new instance
   │             └── User Data script executes
   │                 └── Instance joins Target Group
   │
   └── NO → Continue monitoring
   │
   ▼
3. CPU < 30% for 5 minutes?
   ├── YES → Scale-in alarm triggers
   │         └── ASG terminates instance
   │             └── Target Group removes instance
   │
   └── NO → Continue monitoring
```

### Network Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     VPC - Virtual Private Cloud                             │
│                        CIDR: 10.0.0.0/16                                    │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     Route Table (Public)                                │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │ Destination      │ Target        │ Status                       │   │ │
│  │  ├─────────────────────────────────────────────────────────────────┤   │ │
│  │  │ 10.0.0.0/16      │ local         │ Active (VPC internal)       │   │ │
│  │  │ 0.0.0.0/0        │ igw-xxxxxx    │ Active (Internet Gateway)   │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────┐  │
│  │  Public Subnet - us-east-1a     │  │  Public Subnet - us-east-1b     │  │
│  │  CIDR: 10.0.1.0/24              │  │  CIDR: 10.0.2.0/24              │  │
│  │                                 │  │                                 │  │
│  │  Resources:                     │  │  Resources:                     │  │
│  │  - EC2 Instance 1               │  │  - EC2 Instance 2               │  │
│  │  - ALB Endpoint                 │  │  - ALB Endpoint                 │  │
│  │                                 │  │                                 │  │
│  │  Route Table: Public            │  │  Route Table: Public             │  │
│  │  Internet Access: YES           │  │  Internet Access: YES            │  │
│  └─────────────────────────────────┘  └─────────────────────────────────┘  │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                     Internet Gateway (IGW)                              │ │
│  │  - Provides internet access for public subnets                         │ │
│  │  - Attached to VPC                                                      │ │
│  │  - No additional configuration needed                                   │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

Network ACLs (Default - Associated with VPC):
═════════════════════════════════════════════
┌───────────────────────────────────────────────────────┐
│ Inbound Rules                                          │
├───────────────────────────────────────────────────────┤
│ Rule │ Type   │ Port │ Source      │ Allow/Deny      │
├───────────────────────────────────────────────────────┤
│ 100  │ HTTP   │ 80   │ 0.0.0.0/0   │ ALLOW           │
│ 110  │ HTTPS  │ 443  │ 0.0.0.0/0   │ ALLOW           │
│ 120  │ SSH    │ 22   │ 0.0.0.0/0   │ ALLOW           │
│ *    │ All    │ All  │ 0.0.0.0/0   │ DENY            │
└───────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────┐
│ Outbound Rules                                         │
├───────────────────────────────────────────────────────┤
│ Rule │ Type   │ Port │ Destination  │ Allow/Deny     │
├───────────────────────────────────────────────────────┤
│ 100  │ All    │ All  │ 0.0.0.0/0    │ ALLOW          │
└───────────────────────────────────────────────────────┘
```

---

## Components and Interfaces

### 1. Network Layer (VPC)

#### VPC Configuration

| Parameter | Value | Explanation |
|-----------|-------|-------------|
| **Name** | CapiRentals-VPC | Identificação única para a VPC |
| **CIDR Block** | 10.0.0.0/16 | Fornece 65,536 endereços IP, suficiente para expansão |
| **Tenancy** | Default | Usa hardware compartilhado (mais barato) |

**Analogia:** A VPC é como um terreno privado onde você constrói sua casa. O CIDR é o endereço do terreno.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          VPC Creation                                        │
│                                                                             │
│  AWS Console → VPC → Create VPC                                             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Name tag:         CapiRentals-VPC                                   │   │
│  │  IPv4 CIDR block:  10.0.0.0/16                                       │   │
│  │  IPv6 CIDR block:  No IPv6 CIDR block                                │   │
│  │  Tenancy:          Default                                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Subnet Configuration

**Subnet 1 - us-east-1a (Availability Zone A)**

| Parameter | Value |
|-----------|-------|
| **Name** | CapiRentals-Public-Subnet-AZ-a |
| **VPC** | CapiRentals-VPC |
| **Availability Zone** | us-east-1a |
| **CIDR Block** | 10.0.1.0/24 (256 IPs) |
| **Auto-assign Public IP** | YES |

**Subnet 2 - us-east-1b (Availability Zone B)**

| Parameter | Value |
|-----------|-------|
| **Name** | CapiRentals-Public-Subnet-AZ-b |
| **VPC** | CapiRentals-VPC |
| **Availability Zone** | us-east-1b |
| **CIDR Block** | 10.0.2.0/24 (256 IPs) |
| **Auto-assign Public IP** | YES |

**Analogia:** Sub-redes são como quartos na sua casa. Cada quarto (subnet) está em um andar diferente (Availability Zone) para redundância.

```
Subnet CIDR Allocation:
══════════════════════

VPC CIDR: 10.0.0.0/16
├── Reserved: 10.0.0.0/24 (AWS reserved)
├── Public Subnet AZ-a: 10.0.1.0/24 (256 IPs)
├── Public Subnet AZ-b: 10.0.2.0/24 (256 IPs)
├── Available: 10.0.3.0/24 - 10.0.255.0/24 (future expansion)
```

#### Internet Gateway Configuration

| Parameter | Value |
|-----------|-------|
| **Name** | CapiRentals-IGW |
| **VPC Attachment** | CapiRentals-VPC |

#### Route Table Configuration

| Destination | Target | Purpose |
|-------------|--------|---------|
| 10.0.0.0/16 | local | Tráfego interno da VPC |
| 0.0.0.0/0 | igw-xxxxxx | Tráfego para internet |

---

### 2. Compute Layer (EC2 + ASG)

#### Launch Template Configuration

```yaml
Launch Template: CapiRentals-Launch-Template
════════════════════════════════════════════

Template Settings:
  Name: CapiRentals-Launch-Template
  Version: 1
  Description: Template para instâncias do servidor Capi's Rentals

Instance Configuration:
  AMI: Amazon Linux 2023 (ami-0c7217cdde317cfec)
  Instance Type: t3.micro
  Key Pair: (optional - for SSH access)
  
Network Settings:
  Network: CapiRentals-VPC
  Subnet: (not specified - ASG will choose)
  Auto-assign Public IP: Enabled
  Security Group: CapiRentals-SG

Storage:
  Volume Type: gp3 (General Purpose SSD)
  Size: 8 GB
  Delete on Termination: Yes

Advanced Details:
  IAM Instance Profile: CapiRentals-EC2-Role
  User Data: (see script below)
  Monitoring: Basic (free) or Detailed ($2.10/month)
```

#### User Data Script

```bash
#!/bin/bash
# =============================================================================
# User Data Script - Capi's Rentals Server Initialization
# =============================================================================
# Este script é executado automaticamente quando a instância EC2 é lançada.
# Ele instala e configura o servidor Go da aplicação Capi's Rentals.
# =============================================================================

# 1. Atualizar pacotes do sistema
yum update -y

# 2. Instalar dependências necessárias
yum install -y wget unzip

# 3. Criar diretório da aplicação
mkdir -p /opt/capirentals
cd /opt/capirentals

# 4. Baixar o binário do servidor
# NOTA: O binário deve estar disponível em um bucket S3 ou URL pública
# Para esta competição, assumimos que está disponível via S3 ou upload manual

# Opção A: Download de S3 (requer permissões IAM)
# aws s3 cp s3://seu-bucket/server /opt/capirentals/server

# Opção B: Download de URL pública (se disponível)
wget -O server https://github.com/thiagodavala/workshop-wsc-2024/raw/main/ami-bin/server

# 5. Dar permissão de execução
chmod +x /opt/capirentals/server

# 6. Configurar variáveis de ambiente
export DYNAMO_TABLE="CapiRentalsHash"
export PORT="80"

# 7. Criar arquivo de ambiente para systemd
cat > /etc/capirentals.env <<EOF
DYNAMO_TABLE=CapiRentalsHash
PORT=80
EOF

# 8. Criar serviço systemd para iniciar automaticamente
cat > /etc/systemd/system/capirentals.service <<EOF
[Unit]
Description=Capi's Rentals Hash Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/capirentals
EnvironmentFile=/etc/capirentals.env
ExecStart=/opt/capirentals/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 9. Habilitar e iniciar o serviço
systemctl daemon-reload
systemctl enable capirentals
systemctl start capirentals

# 10. Verificar se o serviço está rodando
sleep 5
systemctl status capirentals --no-pager

# 11. Log de inicialização completa
echo "===========================================" >> /var/log/capirentals-init.log
echo "Capi's Rentals server started at $(date)" >> /var/log/capirentals-init.log
echo "Server listening on port 80" >> /var/log/capirentals-init.log
echo "===========================================" >> /var/log/capirentals-init.log
```

#### Auto Scaling Group Configuration

```yaml
Auto Scaling Group: CapiRentals-ASG
════════════════════════════════════

Basic Configuration:
  Name: CapiRentals-ASG
  Launch Template: CapiRentals-Launch-Template (Version 1)
  
Network Configuration:
  VPC: CapiRentals-VPC
  Availability Zones: us-east-1a, us-east-1b
  Subnets: 
    - CapiRentals-Public-Subnet-AZ-a
    - CapiRentals-Public-Subnet-AZ-b

Instance Requirements:
  Minimum Capacity: 1
  Maximum Capacity: 3
  Desired Capacity: 1

Scaling Policies:
  
  Scale-Out Policy:
    Name: CapiRentals-ScaleOut-Policy
    Type: Simple scaling
    Trigger: CPU > 70% for 5 minutes
    Action: Add 1 instance
    Cooldown: 300 seconds
    
  Scale-In Policy:
    Name: CapiRentals-ScaleIn-Policy
    Type: Simple scaling
    Trigger: CPU < 30% for 5 minutes
    Action: Remove 1 instance
    Cooldown: 300 seconds

Health Check:
  Type: ELB (Elastic Load Balancer)
  Grace Period: 300 seconds
  Health Check Grace Period: 300 seconds

Instance Protection:
  Scale-in Protection: Disabled (allows termination during scale-in)
  
Tags:
  Key: Name
  Value: CapiRentals-Server
  Propagate to Instance: Yes
```

#### Instance Sizing Justification

| Instance Type | vCPUs | Memory | Cost (Learner Lab) | Justification |
|---------------|-------|--------|-------------------|---------------|
| t3.micro | 2 | 1 GB | Included | **RECOMMENDED** - Latest generation, better performance |
| t2.micro | 1 | 1 GB | Included | Alternative if t3 not available |

**Por que t3.micro?**
- Custo zero no Learner Lab
- Suficiente para aplicação Go leve
- Suporta até 3 instâncias dentro do orçamento
- Melhor performance de CPU que t2.micro

---

### 3. Load Balancing Layer (ALB)

#### Application Load Balancer Configuration

```yaml
Application Load Balancer: CapiRentals-ALB
══════════════════════════════════════════

Basic Configuration:
  Name: CapiRentals-ALB
  Scheme: internet-facing
  IP Address Type: IPv4

Network Configuration:
  VPC: CapiRentals-VPC
  Subnets (at least 2):
    - CapiRentals-Public-Subnet-AZ-a
    - CapiRentals-Public-Subnet-AZ-b

Security Settings:
  Security Group: CapiRentals-ALB-SG
  (Allow inbound HTTP from 0.0.0.0/0)
```

#### Listener Configuration

```yaml
Listener: HTTP Listener
══════════════════════

Protocol: HTTP
Port: 80
Default Action: Forward to CapiRentals-Target-Group

Rules:
  - Rule 1 (Default):
      Condition: No conditions (catch-all)
      Action: Forward to CapiRentals-Target-Group
      Priority: Default
```

#### Target Group Configuration

```yaml
Target Group: CapiRentals-Target-Group
══════════════════════════════════════

Basic Configuration:
  Name: CapiRentals-TG
  Target Type: instance
  Protocol: HTTP
  Port: 80
  VPC: CapiRentals-VPC

Health Check Configuration:
  Protocol: HTTP
  Path: /health
  Port: traffic port (80)
  Healthy Threshold: 2 consecutive successes
  Unhealthy Threshold: 3 consecutive failures
  Interval: 30 seconds
  Timeout: 5 seconds
  Success Codes: 200

Target Registration:
  Method: Automatic (via Auto Scaling Group)
  Deregistration Delay: 300 seconds

Attributes:
  Enable Sticky Sessions: No (stateless application)
  Slow Start Duration: 0 seconds
  Load Balancing Algorithm: Round Robin (default)
```

#### Health Check Flow

```
Health Check Process:
═════════════════════

ALB ──────────────────────────────────────────────────────────────────> EC2 Instance
      HTTP GET /health (every 30 seconds)
      
Response Scenarios:

Scenario 1: Instance is HEALTHY
┌─────────────────────────────────────────────────────────────────┐
│ HTTP/1.1 200 OK                                                 │
│ Content-Type: text/plain                                        │
│                                                                 │
│ Healthy!                                                        │
└─────────────────────────────────────────────────────────────────┘
Result: Instance marked healthy, receives traffic

Scenario 2: Instance is UNHEALTHY (timeout/error)
┌─────────────────────────────────────────────────────────────────┐
│ No response within 5 seconds                                    │
└─────────────────────────────────────────────────────────────────┘
Result: After 3 consecutive failures, instance marked unhealthy
         Traffic stops routing to this instance

Unhealthy Threshold Flow:
─────────────────────────
Check 1: FAIL → Unhealthy count: 1
Check 2: FAIL → Unhealthy count: 2  
Check 3: FAIL → Unhealthy count: 3 → MARK UNHEALTHY
         ↓
ASG Health Check detects unhealthy instance
         ↓
ASG terminates and replaces instance
```

#### DNS Naming Strategy

```
DNS Resolution:
══════════════

ALB DNS Name (auto-generated):
┌──────────────────────────────────────────────────────────────────────────────┐
│ CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com                       │
└──────────────────────────────────────────────────────────────────────────────┘

Usage:
- Users access via: http://CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com
- Health check: http://CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com/health
- Calc endpoint: http://CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com/calc?input=test

Note: For production, use Route 53 to create a custom domain like capirentals.example.com
      For Learner Lab competition, use the auto-generated ALB DNS name directly.
```

---

### 4. Data Layer (DynamoDB)

#### Table Schema

```yaml
DynamoDB Table: CapiRentalsHash
════════════════════════════════

Table Name: CapiRentalsHash

Primary Key:
  Partition Key: id (String)
  Sort Key: None

Attributes Stored:
  ┌─────────────────────────────────────────────────────────────────┐
  │ Attribute Name │ Type   │ Description                         │
  ├─────────────────────────────────────────────────────────────────┤
  │ id             │ String │ Base64-encoded SHA256 hash (PK)     │
  │ Texto          │ String │ Original input text                  │
  └─────────────────────────────────────────────────────────────────┘

Capacity Mode: On-Demand
  - Reads: Pay per request
  - Writes: Pay per request
  - No capacity planning required

TTL (Time to Live): Disabled
  (Data is retained indefinitely)

Encryption: Default (AWS-owned key)
  (No additional cost)

Stream: Disabled
  (Not needed for this application)

Global Secondary Indexes: None
  (Simple access pattern by ID only)
```

## Data Models

### DynamoDB Data Model

#### Table: CapiRentalsHash

| Attribute | Type | Description |
|-----------|------|-------------|
| id | String (PK) | Base64-encoded SHA256 hash - serves as unique identifier |
| Texto | String | Original input text submitted by user |

#### Item Structure

```json
{
  "TableName": "CapiRentalsHash",
  "Item": {
    "id": {
      "S": "n4bQgYhMFfXaZ9S5CY3zFg=="
    },
    "Texto": {
      "S": "hello world"
    }
  }
}
```

#### IAM Permissions for DynamoDB

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBPutItem",
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/CapiRentalsHash"
    }
  ]
}
```

## Error Handling

### Application Error Scenarios

The Capi's Rentals application implements error handling at multiple levels:

#### HTTP Error Responses

| Status Code | Scenario | Response |
|-------------|----------|----------|
| 200 OK | Successful hash calculation | JSON with base64_hash |
| 200 OK | Health check successful | "Healthy!" plain text |
| 400 Bad Request | Missing 'input' parameter | Error message explaining required parameter |
| 500 Internal Server Error | DynamoDB write failure | Generic error message (details logged) |

#### DynamoDB Error Handling

- **PutItem errors**: The application catches DynamoDB errors and returns HTTP 500 to the client while logging the error details for troubleshooting
- **Retry logic**: AWS SDK handles transient errors with automatic retries
- **IAM permissions**: Missing permissions result in AccessDenied errors that prevent data persistence

#### ALB Health Check Failures

When an instance becomes unhealthy:
1. ALB marks instance as unhealthy after 3 consecutive failed health checks
2. Traffic stops routing to the unhealthy instance
3. ASG health check detects the failure (if configured with ELB health checks)
4. ASG terminates and replaces the unhealthy instance

#### Auto Scaling Group Failure Scenarios

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| Instance termination | ASG detects missing instance | Launches replacement instance |
| Launch failure | CloudWatch shows unhealthy hosts | Manual investigation required |
| AMI unavailable | Instance launch fails | Update Launch Template with valid AMI |
| Service quota exceeded | Scale-out fails | Request quota increase or reduce max instances |

---

### 5. Security Layer

#### Security Group - Application (EC2)

```yaml
Security Group: CapiRentals-SG
════════════════════════════════

Name: CapiRentals-SG
Description: Security group for Capi's Rentals EC2 instances
VPC: CapiRentals-VPC

Inbound Rules:
┌───────────────────────────────────────────────────────────────────────────┐
│ Type          │ Protocol │ Port │ Source             │ Description      │
├───────────────────────────────────────────────────────────────────────────┤
│ HTTP          │ TCP      │ 80   │ CapiRentals-ALB-SG │ Allow ALB traffic│
│ HTTP          │ TCP      │ 80   │ 0.0.0.0/0          │ Allow direct HTTP│
│ SSH           │ TCP      │ 22   │ 0.0.0.0/0          │ Allow SSH access │
│               │          │      │                    │ (for debugging)  │
└───────────────────────────────────────────────────────────────────────────┘

Outbound Rules:
┌───────────────────────────────────────────────────────────────────────────┐
│ Type          │ Protocol │ Port │ Destination        │ Description      │
├───────────────────────────────────────────────────────────────────────────┤
│ All Traffic   │ All      │ All  │ 0.0.0.0/0          │ Allow all outbound│
│               │          │      │                    │ for DynamoDB,     │
│               │          │      │                    │ CloudWatch, etc. │
└───────────────────────────────────────────────────────────────────────────┘
```

#### Security Group - Load Balancer

```yaml
Security Group: CapiRentals-ALB-SG
════════════════════════════════════

Name: CapiRentals-ALB-SG
Description: Security group for Capi's Rentals ALB
VPC: CapiRentals-VPC

Inbound Rules:
┌───────────────────────────────────────────────────────────────────────────┐
│ Type          │ Protocol │ Port │ Source             │ Description      │
├───────────────────────────────────────────────────────────────────────────┤
│ HTTP          │ TCP      │ 80   │ 0.0.0.0/0          │ Allow internet    │
└───────────────────────────────────────────────────────────────────────────┘

Outbound Rules:
┌───────────────────────────────────────────────────────────────────────────┐
│ Type          │ Protocol │ Port │ Destination        │ Description      │
├───────────────────────────────────────────────────────────────────────────┤
│ HTTP          │ TCP      │ 80   │ CapiRentals-SG     │ Forward to EC2   │
│ All Traffic   │ All      │ All  │ 0.0.0.0/0          │ Default outbound  │
└───────────────────────────────────────────────────────────────────────────┘
```

#### Security Group Flow

```
Traffic Flow with Security Groups:
══════════════════════════════════

Internet (0.0.0.0/0)
       │
       ▼ INBOUND (CapiRentals-ALB-SG): Allow HTTP:80 from 0.0.0.0/0
┌─────────────────┐
│    ALB          │
│ CapiRentals-ALB │
└────────┬────────┘
         │
         ▼ OUTBOUND (CapiRentals-ALB-SG): Allow HTTP:80 to CapiRentals-SG
         │
         ▼ INBOUND (CapiRentals-SG): Allow HTTP:80 from CapiRentals-ALB-SG
┌─────────────────┐
│    EC2          │
│ CapiRentals-Server│
└────────┬────────┘
         │
         ▼ OUTBOUND (CapiRentals-SG): Allow all to 0.0.0.0/0
         │
         ▼ DynamoDB Endpoint (AWS managed)
```

#### IAM Role Configuration

```yaml
IAM Role: CapiRentals-EC2-Role
════════════════════════════════

Role Name: CapiRentals-EC2-Role
Description: Role for EC2 instances to access DynamoDB and CloudWatch
Trust Relationship: ec2.amazonaws.com

Attached Policies:

1. Custom Policy: CapiRentals-DynamoDB-Policy
   ┌─────────────────────────────────────────────────────────────────────────┐
   │ {                                                                       │
   │   "Version": "2012-10-17",                                             │
   │   "Statement": [                                                        │
   │     {                                                                    │
   │       "Effect": "Allow",                                                │
   │       "Action": [                                                        │
   │         "dynamodb:PutItem",                                             │
   │         "dynamodb:GetItem",                                             │
   │         "dynamodb:Query"                                                │
   │       ],                                                                 │
   │       "Resource": "arn:aws:dynamodb:us-east-1:*:table/CapiRentalsHash" │
   │     }                                                                    │
   │   ]                                                                      │
   │ }                                                                        │
   └─────────────────────────────────────────────────────────────────────────┘

2. AWS Managed Policy: CloudWatchAgentServerPolicy
   ┌─────────────────────────────────────────────────────────────────────────┐
   │ Allows EC2 instances to:                                                │
   │ - Write metrics to CloudWatch                                           │
   │ - Write logs to CloudWatch Logs                                         │
   │ - Use Systems Manager                                                   │
   └─────────────────────────────────────────────────────────────────────────┘

Instance Profile: CapiRentals-EC2-Profile
  - Contains the IAM role
  - Attached to Launch Template
```

---

### 6. Monitoring Layer (CloudWatch)

#### Metrics Collection

```yaml
EC2 Metrics (Automatic):
════════════════════════

Metric Name: CPUUtilization
  Namespace: AWS/EC2
  Dimensions: AutoScalingGroupName
  Statistic: Average
  Period: 300 seconds (5 minutes)
  
Metric Name: NetworkIn/Out
  Namespace: AWS/EC2
  Dimensions: InstanceId
  Statistic: Sum
  Period: 300 seconds

ALB Metrics (Automatic):
════════════════════════

Metric Name: RequestCount
  Namespace: AWS/ApplicationELB
  Dimensions: LoadBalancer, TargetGroup
  Statistic: Sum
  Period: 60 seconds

Metric Name: TargetResponseTime
  Namespace: AWS/ApplicationELB
  Dimensions: LoadBalancer
  Statistic: Average
  Period: 60 seconds

Metric Name: HealthyHostCount
  Namespace: AWS/ApplicationELB
  Dimensions: TargetGroup
  Statistic: Average
  Period: 60 seconds

Metric Name: UnHealthyHostCount
  Namespace: AWS/ApplicationELB
  Dimensions: TargetGroup
  Statistic: Average
  Period: 60 seconds
```

#### CloudWatch Alarms

```yaml
Alarm: CapiRentals-HighCPU-Alarm
══════════════════════════════════

Name: CapiRentals-HighCPU-Alarm
Description: Alarm when CPU utilization exceeds 70%

Configuration:
  Namespace: AWS/EC2
  Metric: CPUUtilization
  Dimensions: AutoScalingGroupName = CapiRentals-ASG
  Statistic: Average
  Period: 300 seconds (5 minutes)
  Evaluation Periods: 1
  Threshold: 70%
  Comparison: GreaterThanThreshold
  TreatMissing Data: missing
  
Actions:
  - Notification: (Optional - SNS topic)
  - This alarm is for monitoring; scaling is handled by ASG policies

---

Alarm: CapiRentals-CriticalCPU-Alarm
═════════════════════════════════════

Name: CapiRentals-CriticalCPU-Alarm
Description: Alarm when CPU utilization exceeds 80% (critical threshold)

Configuration:
  Namespace: AWS/EC2
  Metric: CPUUtilization
  Dimensions: AutoScalingGroupName = CapiRentals-ASG
  Statistic: Average
  Period: 300 seconds (5 minutes)
  Evaluation Periods: 1
  Threshold: 80%
  Comparison: GreaterThanThreshold
  TreatMissing Data: breaching (alarm if data missing)

Actions:
  - Notification: (SNS topic for alerting)

---

Alarm: CapiRentals-UnhealthyHosts-Alarm
════════════════════════════════════════

Name: CapiRentals-UnhealthyHosts-Alarm
Description: Alarm when there are unhealthy hosts in the target group

Configuration:
  Namespace: AWS/ApplicationELB
  Metric: UnHealthyHostCount
  Dimensions: TargetGroup = CapiRentals-TG
  Statistic: Average
  Period: 60 seconds
  Evaluation Periods: 3
  Threshold: 0
  Comparison: GreaterThanThreshold

Actions:
  - Notification: (SNS topic for alerting)
```

#### Dashboard Configuration

```yaml
CloudWatch Dashboard: CapiRentals-Dashboard
════════════════════════════════════════════

Widgets:

Row 1: Instance Health
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│ EC2 CPU Utilization               │  │ Healthy Host Count               │
│ (Line chart, last 1 hour)         │  │ (Number widget)                  │
│ - Shows all instances            │  │ - Current healthy instance count │
└──────────────────────────────────┘  └──────────────────────────────────┘

Row 2: Request Metrics
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│ ALB Request Count                │  │ ALB Latency                      │
│ (Line chart, last 1 hour)        │  │ (Line chart, last 1 hour)        │
│ - Total requests per minute      │  │ - Average response time          │
└──────────────────────────────────┘  └──────────────────────────────────┘

Row 3: Auto Scaling
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│ ASG Group Size                   │  │ ASG Capacity                     │
│ (Number widget)                  │  │ (Gauge widget)                   │
│ - Current instance count         │  │ - Min/Max/Desired comparison     │
└──────────────────────────────────┘  └──────────────────────────────────┘

Row 4: Alarms Status
┌───────────────────────────────────────────────────────────────────────┐
│ Alarms Status                                                          │
│ (List widget)                                                          │
│ - Shows all alarms and their current state                            │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Details

### Step-by-Step Deployment Sequence

```
Deployment Order:
════════════════

Phase 1: Network Foundation (10-15 minutes)
────────────────────────────────────────────
Step 1.1: Create VPC (10.0.0.0/16)
Step 1.2: Create Public Subnet AZ-a (10.0.1.0/24)
Step 1.3: Create Public Subnet AZ-b (10.0.2.0/24)
Step 1.4: Create Internet Gateway
Step 1.5: Attach IGW to VPC
Step 1.6: Create Route Table
Step 1.7: Add route to IGW (0.0.0.0/0)
Step 1.8: Associate Route Table with subnets

Phase 2: Security Configuration (5-10 minutes)
──────────────────────────────────────────────
Step 2.1: Create Security Group for ALB
Step 2.2: Create Security Group for EC2
Step 2.3: Create IAM Role for EC2
Step 2.4: Attach DynamoDB policy to role
Step 2.5: Attach CloudWatch policy to role
Step 2.6: Create Instance Profile

Phase 3: Data Layer (5 minutes)
───────────────────────────────
Step 3.1: Create DynamoDB table (CapiRentalsHash)
Step 3.2: Configure On-Demand capacity
Step 3.3: Verify table is active

Phase 4: Load Balancer (10 minutes)
────────────────────────────────────
Step 4.1: Create Target Group
Step 4.2: Create Application Load Balancer
Step 4.3: Create HTTP Listener (port 80)
Step 4.4: Configure health checks

Phase 5: Compute Layer (15-20 minutes)
──────────────────────────────────────
Step 5.1: Create Launch Template
Step 5.2: Configure User Data script
Step 5.3: Attach IAM Instance Profile
Step 5.4: Create Auto Scaling Group
Step 5.5: Configure scaling policies
Step 5.6: Wait for instance launch (5-10 min)

Phase 6: Monitoring (10 minutes)
─────────────────────────────────
Step 6.1: Create CloudWatch alarms
Step 6.2: Create Dashboard
Step 6.3: Verify metrics are flowing

Phase 7: Verification (5 minutes)
──────────────────────────────────
Step 7.1: Test /health endpoint
Step 7.2: Test /calc endpoint
Step 7.3: Verify DynamoDB persistence
Step 7.4: Test ALB DNS name access
```

### Configuration Parameters Summary

```yaml
Complete Configuration Reference:
════════════════════════════════

Network:
  VPC_CIDR: 10.0.0.0/16
  SUBNET_AZ_A_CIDR: 10.0.1.0/24
  SUBNET_AZ_B_CIDR: 10.0.2.0/24
  REGION: us-east-1
  AZ_A: us-east-1a
  AZ_B: us-east-1b

Compute:
  INSTANCE_TYPE: t3.micro
  AMI_ID: ami-0c7217cdde317cfec (Amazon Linux 2023)
  VOLUME_TYPE: gp3
  VOLUME_SIZE: 8
  MIN_INSTANCES: 1
  MAX_INSTANCES: 3
  DESIRED_INSTANCES: 1
  SCALE_OUT_THRESHOLD: 70
  SCALE_IN_THRESHOLD: 30
  SCALE_COOLDOWN: 300

Load Balancer:
  LB_PORT: 80
  LB_PROTOCOL: HTTP
  TARGET_PORT: 80
  HEALTH_PATH: /health
  HEALTH_INTERVAL: 30
  HEALTH_TIMEOUT: 5
  HEALTHY_THRESHOLD: 2
  UNHEALTHY_THRESHOLD: 3

Database:
  TABLE_NAME: CapiRentalsHash
  PARTITION_KEY: id (String)
  CAPACITY_MODE: PAY_PER_REQUEST

Application:
  SERVER_PORT: 80
  DYNAMO_TABLE: CapiRentalsHash
  AWS_REGION: us-east-1

Security:
  INBOUND_PORTS: [80, 22]
  INBOUND_SOURCES: [0.0.0.0/0]
  OUTBOUND: All traffic allowed

Monitoring:
  CPU_ALARM_THRESHOLD: 80
  CPU_ALARM_PERIOD: 300
  METRICS_COLLECTION: Enabled
```

### Environment Variables

```bash
# Environment Variables Required on EC2 Instances
# ================================================

# Application Configuration
export DYNAMO_TABLE="CapiRentalsHash"    # DynamoDB table name
export PORT="80"                          # Server listening port

# AWS Configuration (auto-configured by IAM role)
export AWS_REGION="us-east-1"             # Default region
# AWS SDK will use IAM role credentials automatically

# Optional - For debugging
export AWS_SDK_LOAD_CONFIG="1"           # Load from default config if needed
```

### Verification Procedures

```bash
# Verification Script
# ====================

# 1. Get ALB DNS Name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names CapiRentals-ALB \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: $ALB_DNS"

# 2. Test Health Endpoint
curl -v http://$ALB_DNS/health
# Expected: HTTP 200, body: "Healthy!"

# 3. Test Calc Endpoint
curl "http://$ALB_DNS/calc?input=test"
# Expected: HTTP 200, JSON: {"base64_hash": "..."}

# 4. Test Missing Input
curl "http://$ALB_DNS/calc"
# Expected: HTTP 400, error message

# 5. Verify DynamoDB Data
aws dynamodb scan \
  --table-name CapiRentalsHash \
  --max-items 5
# Expected: Items with "id" and "Texto" attributes

# 6. Check ASG Status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names CapiRentals-ASG
# Expected: MinSize=1, MaxSize=3, Instances count >= 1

# 7. Check CloudWatch Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=CapiRentals-ASG \
  --statistics Average \
  --period 300 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Expected: Recent datapoints with CPU utilization

# 8. Load Test (optional - generates traffic)
for i in {1..100}; do
  curl -s "http://$ALB_DNS/calc?input=test$i" > /dev/null &
done
wait
# Check CloudWatch - should see increased request count
```

---

## Cost Optimization

### Estimated Costs (Learner Lab Credits)

```
Monthly Cost Estimate (Running 24/7 for 30 days)
════════════════════════════════════════════════

Compute (EC2):
┌─────────────────────────────────────────────────────────────────────────┐
│ t3.micro (1 instance × 750 hours/month)                                 │
│ Learner Lab: INCLUDED (within free tier)                                │
│ Regular AWS: ~$8.50/month                                               │
│                                                                          │
│ Max 3 instances: ~$25.50/month (regular)                                │
└─────────────────────────────────────────────────────────────────────────┘

Load Balancer (ALB):
┌─────────────────────────────────────────────────────────────────────────┐
│ ALB Base: ~$16.20/month (0.0225 USD/hour × 720 hours)                   │
│ LCU Charges: ~$0.008 per LCU-hour                                       │
│ Estimated LCU: 1-2 LCU (light traffic)                                  │
│ Total: ~$17-18/month                                                     │
│                                                                          │
│ Learner Lab: May be included or charged separately                      │
└─────────────────────────────────────────────────────────────────────────┘

Database (DynamoDB):
┌─────────────────────────────────────────────────────────────────────────┐
│ On-Demand Pricing:                                                       │
│ - Reads: $1.25 per million request units                                 │
│ - Writes: $1.25 per million request units                                │
│                                                                          │
│ Estimated (1000 requests/day):                                           │
│ - Writes: ~30,000/month = $0.04                                          │
│ - Reads: ~30,000/month = $0.04                                           │
│ - Total: ~$0.08/month                                                    │
│                                                                          │
│ Learner Lab: INCLUDED within DynamoDB limits                            │
└─────────────────────────────────────────────────────────────────────────┘

Monitoring (CloudWatch):
┌─────────────────────────────────────────────────────────────────────────┐
│ Basic metrics: FREE                                                      │
│ Alarms: $0.10 per alarm metric × 3 alarms = $0.30/month                 │
│ Dashboard: $3.00/month (first 3 dashboards free in Learner Lab)         │
│                                                                          │
│ Total: ~$0.30-3.30/month                                                 │
└─────────────────────────────────────────────────────────────────────────┘

Network:
┌─────────────────────────────────────────────────────────────────────────┐
│ Data Transfer OUT: $0.09 per GB (first 1 GB free)                        │
│ Estimated: <1 GB/month for competition                                   │
│ Total: $0 (within free tier)                                             │
└─────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
TOTAL ESTIMATED MONTHLY COST:
═══════════════════════════════════════════════════════════════════════════
  Regular AWS:    ~$26-30/month (1 instance)
                  ~$45-50/month (3 instances at peak)
  
  Learner Lab:   INCLUDED within 50 credits (typically $100+ in resources)
  
  Competition:   Should stay well under budget if not over-provisioned
═══════════════════════════════════════════════════════════════════════════
```

### Cost Optimization Strategies

```yaml
Strategies Applied:
══════════════════

1. Instance Type Selection:
   ✓ Use t3.micro (included in Learner Lab)
   ✓ Avoid larger instance types (t3.small, t3.medium)
   ✗ Don't use burstable instances above t3.micro

2. Auto Scaling Limits:
   ✓ Maximum 3 instances
   ✓ Minimum 1 instance (always running)
   ✓ Scale-out only when needed (CPU > 70%)
   ✓ Scale-in when idle (CPU < 30%)

3. No NAT Gateway:
   ✓ Use public subnets only
   ✓ Eliminates $32/month NAT Gateway cost
   ✓ Instances get public IPs directly

4. DynamoDB On-Demand:
   ✓ No capacity planning needed
   ✓ Pay only for actual usage
   ✓ Free tier may apply in Learner Lab
   ✗ Don't use provisioned capacity (wastes money if underutilized)

5. CloudWatch Optimization:
   ✓ Use basic monitoring (5-minute intervals)
   ✗ Don't enable detailed monitoring ($2.10/month extra)
   ✓ Only create necessary alarms

6. Storage Optimization:
   ✓ 8 GB root volume (minimum)
   ✓ gp3 volume type (best price/performance)
   ✓ Delete on termination enabled

Additional Tips for Competition:
═══════════════════════════════

1. Monitor credits remaining in Learner Lab
2. Stop instances when not competing (if allowed)
3. Don't create unnecessary resources
4. Clean up after competition to avoid charges
5. Use AWS Cost Explorer to track spending
```

### Learner Lab Budget Considerations

```
50 Credits Budget Allocation:
════════════════════════════

Recommended Allocation:
┌─────────────────────────────────────────────────────────────────────────┐
│ Component        │ Credits  │ Justification                             │
├─────────────────────────────────────────────────────────────────────────┤
│ EC2 Instances    │ ~20      │ Main compute cost                         │
│ ALB              │ ~10      │ Load balancer (can't avoid)               │
│ DynamoDB         │ ~5       │ Low usage expected                        │
│ CloudWatch       │ ~5       │ Monitoring and alarms                     │
│ Data Transfer    │ ~5       │ Network traffic                           │
│ Buffer           │ ~5       │ Safety margin for unexpected usage       │
└─────────────────────────────────────────────────────────────────────────┘

Critical Notes:
- ALB is the most expensive single component (~$16-18/month equivalent)
- EC2 costs scale linearly with instance count
- DynamoDB costs are negligible for low traffic
- CloudWatch costs are minimal with basic monitoring

Budget Warning Signs:
─────────────────────
⚠ Credits dropping faster than expected
  → Check if multiple instances running
  → Verify ALB not receiving excessive traffic
  
⚠ Credits nearly depleted
  → Reduce max instances to 2
  → Check for zombie instances (not terminated properly)
  
⚠ Unexpected high DynamoDB costs
  → Check for infinite loops making requests
  → Verify application isn't writing duplicate items unnecessarily
```

---

## Design Decisions

### Decision 1: Public Subnets Instead of Private

```
Decision: Use Public Subnets
════════════════════════════

Options Considered:
┌─────────────────────────────────────────────────────────────────────────┐
│ Option A: Private Subnets + NAT Gateway                                 │
│   - More secure (instances not publicly accessible)                     │
│   - Requires NAT Gateway ($32+/month)                                   │
│   - Complex routing configuration                                        │
│   - Better for production environments                                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Option B: Public Subnets (CHOSEN)                                       │
│   - Simpler configuration                                                │
│   - No NAT Gateway cost                                                  │
│   - Instances can have public IPs                                        │
│   - Acceptable for competition environment                               │
└─────────────────────────────────────────────────────────────────────────┘

Justification:
1. Cost: NAT Gateway costs ~$32/month, would consume significant budget
2. Simplicity: Public subnets are easier to configure for beginners
3. Competition context: Learner Lab may have VPC creation restrictions
4. Security: Application only exposes port 80, SSH can be restricted
5. DynamoDB: Uses AWS endpoints, doesn't require NAT for access

Trade-offs Accepted:
- Instances are publicly accessible (mitigated by Security Group)
- Less "production-ready" architecture (acceptable for competition)
```

### Decision 2: DynamoDB On-Demand Capacity

```
Decision: Use On-Demand Capacity Mode
══════════════════════════════════════

Options Considered:
┌─────────────────────────────────────────────────────────────────────────┐
│ Option A: Provisioned Capacity                                           │
│   - Cheaper for predictable, high traffic                                │
│   - Requires capacity planning                                           │
│   - Can throttle if capacity exceeded                                    │
│   - Need to manage auto-scaling                                          │
├─────────────────────────────────────────────────────────────────────────┤
│ Option B: On-Demand Capacity (CHOSEN)                                   │
│   - No capacity planning required                                        │
│   - Handles any traffic spike automatically                               │
│   - Pay only for what you use                                            │
│   - Slightly higher cost per request                                     │
└─────────────────────────────────────────────────────────────────────────┘

Justification:
1. Unpredictable traffic: Competition traffic is unpredictable
2. Simplicity: No need to calculate RCU/WCU requirements
3. Cost predictability: Won't throttle if traffic spikes
4. Beginner-friendly: One less thing to configure incorrectly
5. Low volume: For expected traffic, cost difference is minimal

Cost Comparison:
- On-Demand: ~$1.25 per million reads/writes
- Provisioned (1 RCU/WCU): ~$0.65 per month + $1.25 per million overage
- Break-even: ~1 million requests/month
- Competition: Likely well under break-even point
```

### Decision 3: t3.micro Instance Type

```
Decision: Use t3.micro Instance Type
═════════════════════════════════════

Options Considered:
┌─────────────────────────────────────────────────────────────────────────┐
│ Option A: t2.micro                                                      │
│   - Older generation                                                    │
│   - 1 vCPU, 1 GB RAM                                                    │
│   - Lower performance                                                   │
│   - Same cost as t3.micro                                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Option B: t3.micro (CHOSEN)                                            │
│   - Latest burstable instance                                           │
│   - 2 vCPU, 1 GB RAM                                                    │
│   - Better CPU performance                                               │
│   - Included in Learner Lab                                             │
├─────────────────────────────────────────────────────────────────────────┤
│ Option C: t3.small                                                       │
│   - 2 vCPU, 2 GB RAM                                                    │
│   - Double the cost                                                      │
│   - Overkill for this application                                       │
└─────────────────────────────────────────────────────────────────────────┘

Justification:
1. Performance: Go application is lightweight, t3.micro is sufficient
2. Cost: t3.micro is included in Learner Lab free tier
3. Memory: 1 GB RAM is enough for the binary (minimal memory footprint)
4. CPU: 2 vCPUs can handle expected traffic
5. Burstable: Can burst for short periods if needed

Resource Utilization Estimate:
- Application binary: ~10-20 MB memory
- Per request memory: ~1-5 MB
- Total under normal load: ~100-200 MB
- Headroom: 800 MB available for spikes
```

### Decision 4: Maximum 3 Instances

```
Decision: Limit ASG Maximum to 3 Instances
════════════════════════════════════════════

Options Considered:
┌─────────────────────────────────────────────────────────────────────────┐
│ Option A: Maximum 1 Instance                                            │
│   - Lowest cost                                                          │
│   - No high availability                                                 │
│   - Single point of failure                                              │
│   - Not acceptable for production                                        │
├─────────────────────────────────────────────────────────────────────────┤
│ Option B: Maximum 3 Instances (CHOSEN)                                  │
│   - Good balance of cost and availability                                │
│   - Can handle traffic spikes                                             │
│   - High availability with 2+ AZs                                        │
│   - Within budget constraints                                             │
├─────────────────────────────────────────────────────────────────────────┤
│ Option C: Maximum 5+ Instances                                          │
│   - Better scaling capability                                            │
│   - Higher cost                                                           │
│   - May exceed budget                                                    │
│   - Overkill for expected traffic                                        │
└─────────────────────────────────────────────────────────────────────────┘

Justification:
1. Budget: 3 instances × t3.micro fits within 50 credits
2. Availability: With 2 AZs, can survive 1 AZ failure
3. Scaling: Can triple capacity during traffic spikes
4. Competition: Expected load doesn't require more
5. Cost control: Hard limit prevents runaway costs

Scaling Scenario:
- Normal: 1 instance (baseline)
- Moderate load: 2 instances (CPU 70-85%)
- High load: 3 instances (CPU > 85%)
- Maximum capacity: 3 instances handles ~3× baseline traffic
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Hash Calculation Round-Trip

*For any* valid input string, the `/calc` endpoint shall return a JSON response containing a valid base64-encoded SHA256 hash that uniquely represents the input.

**Validates: Requirements 3.2**

### Property 2: Data Persistence Consistency

*For any* request to the `/calc` endpoint with a valid input parameter, the system shall persist the input text to the DynamoDB table with the generated hash as the primary key.

**Validates: Requirements 2.2**

### Property 3: Health Endpoint Stability

*For any* HTTP request to the `/health` endpoint, the system shall return HTTP 200 with the exact response body "Healthy!" when the service is operational.

**Validates: Requirements 3.1**

### Property 4: Input Validation Error Handling

*For any* HTTP request to the `/calc` endpoint without the `input` query parameter, the system shall return HTTP 400 with an appropriate error message.

**Validates: Requirements 3.3**

### Property 5: ALB Traffic Distribution

*For any* HTTP request received by the Application Load Balancer, the request shall be forwarded to a healthy EC2 instance in the Target Group.

**Validates: Requirements 4.3**

---

## Testing Strategy

### Unit Tests

Unit tests should cover:
- Specific input/output examples for hash calculation
- Edge cases for empty input, special characters, Unicode
- Error conditions for missing parameters
- JSON response format validation

### Integration Tests

Integration tests should cover:
- End-to-end request flow through ALB to EC2
- DynamoDB persistence verification
- Health check mechanism
- Auto Scaling Group instance launch/termination (smoke test)
- Multi-AZ failover simulation (manual test)

### Property Tests

Property-based tests should cover:
- Hash calculation correctness for arbitrary input strings
- Data persistence for all valid inputs
- Health endpoint consistency across multiple requests

**Test Configuration:**
- Minimum 100 iterations per property test
- Each property test must reference its design document property
- Tag format: **Feature: capirentals-aws-deployment, Property {number}: {property_text}**

---

## Appendix: Portuguese Instructions Summary

### Instruções de Implantação (Resumo)

```
Resumo do Processo de Implantação:
══════════════════════════════════

Fase 1: Rede (VPC)
  1. Criar VPC com CIDR 10.0.0.0/16
  2. Criar sub-redes públicas em 2 AZs
  3. Criar Internet Gateway
  4. Configurar tabelas de roteamento

Fase 2: Segurança
  1. Criar Security Groups (ALB e EC2)
  2. Criar IAM Role para EC2
  3. Anexar políticas DynamoDB e CloudWatch

Fase 3: Banco de Dados
  1. Criar tabela DynamoDB "CapiRentalsHash"
  2. Configurar capacidade sob demanda

Fase 4: Load Balancer
  1. Criar Target Group
  2. Criar Application Load Balancer
  3. Configurar listener HTTP porta 80
  4. Configurar health checks

Fase 5: Computação
  1. Criar Launch Template com User Data
  2. Criar Auto Scaling Group
  3. Configurar políticas de scaling

Fase 6: Monitoramento
  1. Criar alarmes CloudWatch
  2. Criar dashboard

Verificação:
  curl http://ALB-DNS/health
  curl http://ALB-DNS/calc?input=teste
```

---

## Conclusion

This design provides a complete, cost-effective architecture for deploying Capi's Rentals hash service to AWS within Learner Lab constraints. The architecture prioritizes simplicity and cost control while maintaining high availability and automatic scaling capabilities.

Key design principles applied:
1. **Cost optimization**: Public subnets, on-demand DynamoDB, maximum 3 instances
2. **High availability**: Multi-AZ deployment, automatic scaling, health checks
3. **Beginner-friendly**: Step-by-step instructions, clear explanations, visual diagrams
4. **Competition-ready**: Fits within 50-credit budget, compatible with Learner Lab restrictions

The deployment sequence is designed to minimize dependencies and allow verification at each phase before proceeding to the next.
