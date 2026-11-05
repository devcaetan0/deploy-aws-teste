# Implementation Plan: Capi's Rentals AWS Deployment

## Overview

This implementation plan provides step-by-step instructions for deploying the Capi's Rentals hash service on AWS infrastructure. The deployment uses an Application Load Balancer (ALB) with an Auto Scaling Group (ASG) of EC2 instances to provide a scalable, highly available architecture. The architecture follows AWS best practices for a stateless web application that can horizontally scale based on demand.

**Target Audience:** Beginners with basic AWS Console navigation skills

**Estimated Total Time:** 2-3 hours

**Architecture Components:**
- **DynamoDB Table:** CapiRentalsHash (data persistence)
- **IAM Role:** EC2 instance role with DynamoDB and CloudWatch permissions
- **VPC Infrastructure:** Public subnets in 2 Availability Zones
- **Security Groups:** ALB (ingress) and EC2 (internal communication)
- **Launch Template:** EC2 configuration with User Data script
- **Application Load Balancer:** HTTP traffic distribution
- **Auto Scaling Group:** Automatic instance scaling (1-4 instances)

---

## Tasks

### Phase 1: Preparation

- [ ] 1. Start AWS Learner Lab and Verify Access
  - **Type:** Required
  - **Time Estimate:** 5 minutes
  - **Dependencies:** None
  
  **Objective:** Start the AWS Learner Lab session and verify access to required AWS services.
  
  **Instructions:**
  1. Navigate to AWS Academy Learner Lab (https://awsacademy.instructure.com/)
  2. Click on "Launch Lab" button
  3. Wait for lab status to show "Lab is ready" (green indicator)
  4. Click "AWS Console" button to open the AWS Management Console
  5. Verify you are in the correct region (top-right corner): **US East (N. Virginia) us-east-1** (Região Leste dos EUA)
  6. Navigate to EC2 Dashboard:
     - In the search bar at top, type "EC2"
     - Click on "EC2" under Services
  7. Verify your lab budget/credits remaining in the Learner Lab interface
  
  **Verification Criteria:**
  - AWS Console is accessible
  - EC2 Dashboard loads without errors
  - Region is set to us-east-1 (N. Virginia)
  
  **Expected Result:**
  - EC2 Dashboard displays with "Launch instance" button visible
  - No "Access Denied" or permission error messages
  
  **Troubleshooting Tips:**
  - If lab doesn't start, try refreshing the browser page
  - If AWS Console shows access errors, return to Learner Lab and verify lab status
  - If region is incorrect, click the region dropdown (top-right) and select "US East (N. Virginia)"
  
  **Portuguese Terms:**
  - Região (Region)
  - Console de Gerenciamento (Management Console)
  - Painel (Dashboard)

- [ ] 2. Create DynamoDB Table (CapiRentalsHash)
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 1 (AWS access verified)
  
  **Objective:** Create the DynamoDB table that the hash service uses for data persistence.
  
  **Instructions:**
  1. Navigate to DynamoDB:
     - In the AWS Console search bar, type "DynamoDB"
     - Click on "DynamoDB" under Services
  
  2. Create the table:
     - Click the orange "Create table" button (Criar tabela)
  
  3. Configure table settings:
     - **Table name** (Nome da tabela): `CapiRentalsHash`
     - **Partition key** (Chave de partição): `id`
     - **Partition key type**: String
     - Leave "Sort key" (Chave de classificação) empty
  
  4. Table settings (keep defaults):
     - **Table type**: Standard
     - **Read/Write capacity mode**: On-demand (recommended for variable traffic)
     - **Encryption at rest**: Default (owned by Amazon DynamoDB)
  
  5. Click "Create table" at the bottom
  
  6. Wait for table creation:
     - Table status will change from "Creating" to "Active"
     - This takes approximately 30-60 seconds
  
  **Verification Criteria:**
  - Table named "CapiRentalsHash" appears in the table list
  - Table status shows "Active" (Ativo)
  - Table has partition key "id" (String type)
  
  **Expected Result:**
  - DynamoDB Dashboard shows the new table in the list
  - Clicking on the table name displays table details with items count (initially 0)
  
  **Troubleshooting Tips:**
  - If table name is already taken, the table may already exist - verify its configuration
  - If you get permission errors, verify your Learner Lab is still active
  - If creation fails, check the AWS Service Health Dashboard for DynamoDB issues
  
  **Portuguese Terms:**
  - Tabela (Table)
  - Chave de partição (Partition key)
  - Capacidade sob demanda (On-demand capacity)

- [ ] 3. Create IAM Role for EC2 (DynamoDB + CloudWatch Permissions)
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 1 (AWS access verified)
  
  **Objective:** Create an IAM role that EC2 instances will assume to access DynamoDB and CloudWatch services.
  
  **Instructions:**
  1. Navigate to IAM:
     - In the AWS Console search bar, type "IAM"
     - Click on "IAM" under Services
  
  2. Create a new role:
     - In the left sidebar, click "Roles" (Funções)
     - Click the orange "Create role" button (Criar função)
  
  3. Select trusted entity:
     - **Trusted entity type**: AWS service (Serviço da AWS)
     - **Service or use case**: EC2
     - **Use case**: EC2 - Allows EC2 instances to call AWS services on your behalf
     - Click "Next"
  
  4. Add permissions policies:
     - In the search box, type "DynamoDBFullAccess"
     - Check the box next to `AmazonDynamoDBFullAccess`
     - Clear the search and type "CloudWatchAgentServerPolicy"
     - Check the box next to `CloudWatchAgentServerPolicy`
     - Clear the search and type "CloudWatchFullAccess"
     - Check the box next to `CloudWatchFullAccess`
     - Click "Next"
  
  5. Name and create the role:
     - **Role name** (Nome da função): `EC2-DynamoDB-CloudWatch-Role`
     - **Description**: `Role for EC2 instances to access DynamoDB and CloudWatch`
     - Click "Create role"
  
  6. Verify role creation:
     - Role should appear in the roles list
     - Click on the role name to view details
     - Verify the three policies are attached
  
  **Verification Criteria:**
  - Role named "EC2-DynamoDB-CloudWatch-Role" exists
  - Role has trust relationship with EC2 service
  - Role has three managed policies attached:
    - AmazonDynamoDBFullAccess
    - CloudWatchAgentServerPolicy
    - CloudWatchFullAccess
  
  **Expected Result:**
  - IAM Dashboard > Roles shows the new role
  - Role details page shows the permissions and trust relationships
  
  **Troubleshooting Tips:**
  - If you can't find specific policies, use the search filters and verify exact policy names
  - In Learner Lab, some policies may be restricted - use the closest available alternative
  - If role creation fails, check IAM service limits in your account
  
  **Portuguese Terms:**
  - Função (Role)
  - Política de permissões (Permissions policy)
  - Relacionamento de confiança (Trust relationship)

---

### Phase 2: Network Infrastructure

- [ ] 4. Check/Create VPC Configuration
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 1 (AWS access verified)
  
  **Objective:** Verify the existing VPC configuration in the Learner Lab and understand the network architecture.
  
  **Instructions:**
  1. Navigate to VPC:
     - In the AWS Console search bar, type "VPC"
     - Click on "VPC" under Services
  
  2. Check existing VPC:
     - In the left sidebar, click "Your VPCs" (Suas VPCs)
     - You should see a default VPC (starts with "vpc-...")
     - Note the **VPC ID** (e.g., vpc-0abc123def456)
     - **Important:** In Learner Lab, you typically cannot create new VPCs - use the existing one
  
  3. Verify VPC configuration:
     - Click on the VPC ID to view details
     - Note the **CIDR block** (e.g., 172.31.0.0/16 or 10.0.0.0/16)
     - Verify the VPC is in the correct region (us-east-1)
  
  4. Check VPC attributes:
     - Ensure "DNS resolution" is enabled (Sim/Não)
     - Ensure "DNS hostnames" is enabled (Sim/Não)
     - If disabled, click "Actions" > "Edit DNS resolution" and enable it
     - If disabled, click "Actions" > "Edit DNS hostnames" and enable it
  
  **Verification Criteria:**
  - At least one VPC exists in the region
  - VPC has DNS resolution and DNS hostnames enabled
  - You have noted the VPC ID for future tasks
  
  **Expected Result:**
  - VPC Dashboard shows at least one VPC
  - VPC details page shows enabled DNS settings
  - VPC CIDR block is documented for reference
  
  **Troubleshooting Tips:**
  - If no VPC exists, the Learner Lab may have issues - restart the lab
  - If you cannot enable DNS settings, proceed anyway - most default VPCs have these enabled
  - Learner Lab typically provides a default VPC with pre-configured settings
  
  **Portuguese Terms:**
  - VPC (Virtual Private Cloud) - Nuvem Virtual Privada
  - Bloco CIDR (CIDR block)
  - Resolução de DNS (DNS resolution)

- [ ] 5. Create Public Subnets in 2 AZs
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 4 (VPC configuration verified)
  
  **Objective:** Create two public subnets in different Availability Zones for high availability.
  
  **Instructions:**
  1. Navigate to Subnets:
     - In VPC Dashboard left sidebar, click "Subnets" (Sub-redes)
     - Review existing subnets - note which ones are associated with your VPC
  
  2. Check if you need to create new subnets:
     - If you have at least 2 public subnets in different AZs, note their **Subnet IDs**
     - If not, proceed to create new subnets
  
  3. Create first public subnet:
     - Click "Create subnet" (Criar sub-rede)
     - **VPC ID**: Select your VPC from dropdown
     - **Subnet name** (Nome da sub-rede): `CapiRentals-Public-Subnet-1`
     - **Availability Zone** (Zona de disponibilidade): `us-east-1a`
     - **IPv4 CIDR block**: Enter a block within your VPC CIDR (e.g., `172.31.64.0/20`)
       - Tip: Check existing subnets to find available IP ranges
     - Click "Create subnet"
  
  4. Create second public subnet:
     - Click "Create subnet" again
     - **VPC ID**: Select your VPC from dropdown
     - **Subnet name**: `CapiRentals-Public-Subnet-2`
     - **Availability Zone**: `us-east-1b` (different from first)
     - **IPv4 CIDR block**: Enter a different block (e.g., `172.31.80.0/20`)
     - Click "Create subnet"
  
  5. Enable auto-assign public IP for subnets:
     - Select `CapiRentals-Public-Subnet-1`
     - Click "Actions" > "Edit subnet settings" (Editar configurações de sub-rede)
     - Check "Enable auto-assign public IPv4 address" (Habilitar atribuição automática de endereço IPv4 público)
     - Click "Save"
     - Repeat for `CapiRentals-Public-Subnet-2`
  
  **Verification Criteria:**
  - Two subnets exist in different Availability Zones (us-east-1a and us-east-1b)
  - Both subnets are associated with your VPC
  - Both subnets have auto-assign public IP enabled
  - Subnets have non-overlapping CIDR blocks
  
  **Expected Result:**
  - Subnets list shows both new subnets
  - Each subnet has a unique Subnet ID
  - "Auto-assign public IP" column shows "Yes" for both
  
  **Troubleshooting Tips:**
  - If CIDR block conflicts occur, try different ranges (check existing subnets first)
  - If you cannot create subnets, use existing public subnets in the VPC
  - Learner Lab may have pre-created subnets - verify they span multiple AZs
  
  **Portuguese Terms:**
  - Sub-rede (Subnet)
  - Zona de disponibilidade (Availability Zone)
  - Endereço IP público (Public IP address)

- [ ] 6. Create Internet Gateway and Route Tables
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 5 (Public subnets created)
  
  **Objective:** Ensure Internet Gateway exists and configure route tables for public internet access.
  
  **Instructions:**
  1. Check/Create Internet Gateway:
     - In VPC Dashboard left sidebar, click "Internet Gateways" (Gateways da Internet)
     - If an IGW is already attached to your VPC, note its ID
     - If not, click "Create internet gateway" (Criar gateway da internet)
       - **Name tag**: `CapiRentals-IGW`
       - Click "Create internet gateway"
       - Select the new IGW, click "Actions" > "Attach to VPC"
       - Select your VPC from dropdown
       - Click "Attach internet gateway"
  
  2. Check/Create Public Route Table:
     - In VPC Dashboard left sidebar, click "Route Tables" (Tabelas de rotas)
     - Look for a route table with a route to "0.0.0.0/0" pointing to an Internet Gateway
     - If none exists:
       - Click "Create route table" (Criar tabela de rotas)
       - **Name tag**: `CapiRentals-Public-Route-Table`
       - **VPC**: Select your VPC
       - Click "Create route table"
  
  3. Add route to Internet Gateway:
     - Select the route table
     - Click "Routes" tab (Rotas)
     - Click "Edit routes" (Editar rotas)
     - Click "Add route"
     - **Destination**: `0.0.0.0/0`
     - **Target**: Select "Internet Gateway" and choose your IGW
     - Click "Save changes"
  
  4. Associate subnets with route table:
     - Select the public route table
     - Click "Subnet Associations" tab (Associações de sub-redes)
     - Click "Edit subnet associations" (Editar associações de sub-redes)
     - Check the boxes for `CapiRentals-Public-Subnet-1` and `CapiRentals-Public-Subnet-2`
     - Click "Save associations"
  
  **Verification Criteria:**
  - Internet Gateway is attached to your VPC
  - Route table has a route: 0.0.0.0/0 → Internet Gateway
  - Both public subnets are associated with the public route table
  
  **Expected Result:**
  - Internet Gateways list shows IGW attached to your VPC
  - Route table details show the internet route
  - Subnet associations show both public subnets
  
  **Troubleshooting Tips:**
  - If IGW already exists and is attached, proceed to route table configuration
  - If you cannot create IGW, the VPC may already have one attached
  - Default VPCs usually have a default route table with internet access pre-configured
  
  **Portuguese Terms:**
  - Gateway da Internet (Internet Gateway)
  - Tabela de rotas (Route Table)
  - Associação de sub-rede (Subnet association)

- [ ] 7. Create Security Groups (ALB and EC2)
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 4 (VPC configuration verified)
  
  **Objective:** Create two security groups: one for the Application Load Balancer (allows HTTP from internet) and one for EC2 instances (allows traffic only from ALB).
  
  **Instructions:**
  1. Navigate to Security Groups:
     - In VPC Dashboard left sidebar, click "Security Groups" (Grupos de segurança)
  
  2. Create ALB Security Group:
     - Click "Create security group" (Criar grupo de segurança)
     - **Security group name**: `CapiRentals-ALB-SG`
     - **Description**: `Security group for Application Load Balancer - allows HTTP from internet`
     - **VPC**: Select your VPC
     - **Inbound rules** (Regras de entrada):
       - Click "Add rule"
       - **Type**: HTTP
       - **Port**: 80
       - **Source**: 0.0.0.0/0 (Anywhere IPv4)
       - (Optional) Add another rule for IPv6: ::/0
     - **Outbound rules** (Regras de saída): Keep default (All traffic, 0.0.0.0/0)
     - Click "Create security group"
     - **Note the Security Group ID** (e.g., sg-0abc123def456)
  
  3. Create EC2 Security Group:
     - Click "Create security group" again
     - **Security group name**: `CapiRentals-EC2-SG`
     - **Description**: `Security group for EC2 instances - allows traffic from ALB only`
     - **VPC**: Select your VPC
     - **Inbound rules**:
       - Click "Add rule"
       - **Type**: HTTP
       - **Port**: 80
       - **Source**: Click in the box, start typing "CapiRentals-ALB-SG" and select it
       - (This allows traffic only from the ALB security group)
       - **Add another rule for SSH** (optional for debugging):
       - **Type**: SSH
       - **Port**: 22
       - **Source**: 0.0.0.0/0 (or restrict to your IP for security)
     - **Outbound rules**: Keep default (All traffic, 0.0.0.0/0)
     - Click "Create security group"
     - **Note the Security Group ID**
  
  **Verification Criteria:**
  - Two security groups exist: CapiRentals-ALB-SG and CapiRentals-EC2-SG
  - ALB-SG allows inbound HTTP (port 80) from 0.0.0.0/0
  - EC2-SG allows inbound HTTP (port 80) only from ALB-SG
  - Both security groups allow all outbound traffic
  
  **Expected Result:**
  - Security Groups list shows both groups
  - Clicking each group shows correct inbound/outbound rules
  - EC2-SG inbound rule shows ALB-SG ID as the source
  
  **Troubleshooting Tips:**
  - If you cannot select ALB-SG as source for EC2-SG, use the ALB-SG ID manually (sg-...)
  - SSH access is optional - remove if you won't need direct instance access
  - Ensure both security groups are in the same VPC
  
  **Portuguese Terms:**
  - Grupo de segurança (Security Group)
  - Regras de entrada (Inbound rules)
  - Regras de saída (Outbound rules)
  - Origem (Source)

---

### Phase 3: Compute Infrastructure

- [ ] 8. Create Launch Template with User Data Script
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 2 (DynamoDB table), Task 3 (IAM role), Task 7 (EC2 security group)
  
  **Objective:** Create a launch template that defines EC2 instance configuration including the User Data script to install and run the hash service.
  
  **Instructions:**
  1. Navigate to EC2 > Launch Templates:
     - In the AWS Console search bar, type "EC2" and click to open
     - In the EC2 Dashboard left sidebar, under "Instances", click "Launch Templates" (Modelos de execução)
     - Click "Create launch template" (Criar modelo de execução)
  
  2. Configure basic settings:
     - **Launch template name**: `CapiRentals-Launch-Template`
     - **Template version description**: `Initial version with hash server`
     - Check "Provide guidance to help me set up a template that I can use with EC2 Auto Scaling"
  
  3. Configure instance settings:
     - **AMI** (Amazon Machine Image):
       - Click "Browse more AMIs"
       - Select "Amazon Linux 2023 AMI" or "Amazon Linux 2 AMI (HVM)"
       - Choose the latest version
     - **Instance type**: `t2.micro` or `t3.micro` (free tier eligible)
     - **Key pair** (login):
       - If you have an existing key pair, select it
       - If not, create a new key pair or proceed without one (not recommended for production)
  
  4. Configure networking:
     - **Network settings**:
       - **Subnet**: Don't include in template (select at launch)
       - **Security groups**: Select `CapiRentals-EC2-SG`
  
  5. Configure storage:
     - **Storage** (Volumes): Keep default (8 GB gp2 or gp3)
  
  6. Configure IAM role:
     - **Advanced details** > **IAM instance profile**:
       - Select `EC2-DynamoDB-CloudWatch-Role`
  
  7. Add User Data script:
     - Scroll to **Advanced details** > **User data** (Dados do usuário)
     - Paste the following script:
     
     ```bash
     #!/bin/bash
     # Update system packages
     yum update -y
     
     # Install required packages
     yum install -y wget unzip aws-cli
     
     # Create application directory
     mkdir -p /opt/capirentals
     cd /opt/capirentals
     
     # Download the server binary from GitHub
     wget -O server https://github.com/thiagodavala/workshop-wsc-2024/raw/main/ami-bin/server
     
     # Make the binary executable
     chmod +x server
     
     # Set environment variables
     export AWS_REGION=us-east-1
     export DYNAMODB_TABLE=CapiRentalsHash
     
     # Create systemd service file
     cat > /etc/systemd/system/capirentals.service << 'EOF'
     [Unit]
     Description=Capi's Rentals Hash Server
     After=network.target
     
     [Service]
     Type=simple
     User=root
     WorkingDirectory=/opt/capirentals
     Environment="AWS_REGION=us-east-1"
     Environment="DYNAMODB_TABLE=CapiRentalsHash"
     ExecStart=/opt/capirentals/server
     Restart=always
     RestartSec=5
     
     [Install]
     WantedBy=multi-user.target
     EOF
     
     # Enable and start the service
     systemctl daemon-reload
     systemctl enable capirentals
     systemctl start capirentals
     
     # Log completion
     echo "Capi's Rentals server deployment completed at $(date)" >> /var/log/capirentals-deploy.log
     ```
  
  8. Click "Create launch template"
  
  **Verification Criteria:**
  - Launch template named "CapiRentals-Launch-Template" exists
  - Template has AMI, instance type, and security group configured
  - Template has IAM role attached
  - Template has User Data script with proper deployment logic
  
  **Expected Result:**
  - Launch Templates list shows the new template
  - Clicking on template shows all configured settings
  - User data section contains the deployment script
  
  **Troubleshooting Tips:**
  - If AMI is not found, select a different region or use Amazon Linux 2
  - If IAM role is not visible, verify the role was created successfully in Task 3
  - User Data script must start with `#!/bin/bash`
  - Test the script syntax by checking for bash errors
  
  **Portuguese Terms:**
  - Modelo de execução (Launch Template)
  - Dados do usuário (User data)
  - Perfil de instância IAM (IAM instance profile)

- [ ] 9. Create Application Load Balancer and Target Group
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 5 (Public subnets), Task 7 (ALB security group)
  
  **Objective:** Create an Application Load Balancer to distribute HTTP traffic across EC2 instances.
  
  **Instructions:**
  1. Navigate to Load Balancers:
     - In EC2 Dashboard left sidebar, under "Load Balancing", click "Load Balancers" (Balanceadores de carga)
     - Click "Create Load Balancer" (Criar balanceador de carga)
  
  2. Select Load Balancer type:
     - Under "Application Load Balancer", click "Create" (Criar)
  
  3. Configure Basic settings:
     - **Load balancer name**: `CapiRentals-ALB`
     - **Scheme**: Internet-facing (Voltado para a internet)
     - **IP address type**: IPv4
  
  4. Configure Network mapping:
     - **VPC**: Select your VPC
     - **Mappings** (Mapeamentos):
       - Check `us-east-1a` and select `CapiRentals-Public-Subnet-1`
       - Check `us-east-1b` and select `CapiRentals-Public-Subnet-2`
  
  5. Configure Security groups:
     - **Security groups**: Select `CapiRentals-ALB-SG`
     - Remove the default security group if attached
  
  6. Configure Listeners and routing:
     - **Listener** (Ouvinte):
       - **Protocol**: HTTP
       - **Port**: 80
       - **Default action**: Forward to target group
       - Click "Create target group" (Criar grupo de destino) - this opens a new tab
    
     7. Create Target Group (in new tab):
        - **Target type**: Instances
        - **Target group name**: `CapiRentals-TG`
        - **Protocol**: HTTP
        - **Port**: 80
        - **VPC**: Select your VPC
        - **Health checks** (Verificações de integridade):
          - **Health check protocol**: HTTP
          - **Health check path**: `/health`
          - **Advanced health check settings**:
            - **Healthy threshold**: 2
            - **Unhealthy threshold**: 2
            - **Timeout**: 5 seconds
            - **Interval**: 10 seconds
        - Click "Next"
        - Don't register targets yet (ASG will do this)
        - Click "Create target group"
    
  8. Return to ALB creation tab:
     - Refresh the target group dropdown
     - Select `CapiRentals-TG`
  
  9. Review and create:
     - Click "Create load balancer"
     - Wait for creation (takes 2-3 minutes)
  
  10. Note the ALB DNS name:
      - After creation, select the ALB
      - Copy the **DNS name** (e.g., CapiRentals-ALB-123456.us-east-1.elb.amazonaws.com)
      - This will be used to access the application
  
  **Verification Criteria:**
  - Application Load Balancer named "CapiRentals-ALB" exists
  - ALB status is "Active" (Ativo)
  - Target Group named "CapiRentals-TG" exists
  - ALB has listeners configured on port 80
  - ALB is in both public subnets
  
  **Expected Result:**
  - Load Balancers list shows the new ALB with "Active" status
  - Target Groups list shows the new target group
  - ALB details show DNS name and listener configuration
  
  **Troubleshooting Tips:**
  - If ALB creation fails, verify subnets are in different AZs
  - If target group doesn't appear, refresh the dropdown after creating it
  - ALB provisioning takes 2-5 minutes - wait before proceeding
  - If health checks fail initially, instances may not be registered yet
  
  **Portuguese Terms:**
  - Balanceador de carga (Load Balancer)
  - Grupo de destino (Target Group)
  - Ouvinte (Listener)
  - Verificação de integridade (Health check)

- [ ] 10. Create Auto Scaling Group
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 8 (Launch template), Task 9 (Target Group)
  
  **Objective:** Create an Auto Scaling Group that automatically manages EC2 instances based on load.
  
  **Instructions:**
  1. Navigate to Auto Scaling Groups:
     - In EC2 Dashboard left sidebar, under "Auto Scaling", click "Auto Scaling Groups" (Grupos de Auto Scaling)
     - Click "Create Auto Scaling group" (Criar grupo de Auto Scaling)
  
  2. Step 1 - Choose launch template or configuration:
     - **Auto Scaling group name**: `CapiRentals-ASG`
     - **Launch template**: Select `CapiRentals-Launch-Template`
     - Verify the template version is "Latest" or "Default"
     - Click "Next"
  
  3. Step 2 - Choose instance launch options:
     - **Network**:
       - **VPC**: Select your VPC
       - **Availability Zones and subnets**:
         - Select `CapiRentals-Public-Subnet-1`
         - Select `CapiRentals-Public-Subnet-2`
     - Click "Next"
  
  4. Step 3 - Configure advanced options:
     - **Load balancing**:
       - Select "Attach to an existing load balancer"
       - **Existing load balancer types**: Select "Choose from your load balancer target groups"
       - **Target groups**: Select `CapiRentals-TG`
     - **Health checks**:
       - **Health check type**: Check both "EC2" and "ELB"
       - **Health check grace period**: 60 seconds
     - **Additional settings**:
       - Check "Enable group metrics collection in CloudWatch" (optional but recommended)
     - Click "Next"
  
  5. Step 4 - Configure group size and scaling policies:
     - **Group size**:
       - **Desired capacity**: 1
       - **Minimum capacity**: 1
       - **Maximum capacity**: 4
     - **Scaling policies**:
       - Select "Target tracking scaling policy"
       - **Policy name**: `CapiRentals-CPU-Scaling-Policy`
       - **Metric type**: Average CPU utilization
       - **Target value**: 70 percent
       - Check "Disable scale in to reduce the number of instances" (optional - prevents aggressive scale-in)
     - Click "Next"
  
  6. Step 5 - Add notifications:
     - Skip or configure SNS notifications for scaling events (optional)
     - Click "Next"
  
  7. Step 6 - Add tags:
     - Click "Add tag"
     - **Key**: `Name`
     - **Value**: `CapiRentals-Server`
     - Check "Tag new instances"
     - (Optional) Add more tags like `Environment: Production`
     - Click "Next"
  
  8. Step 7 - Review and create:
     - Review all settings
     - Click "Create Auto Scaling group"
  
  **Verification Criteria:**
  - Auto Scaling Group named "CapiRentals-ASG" exists
  - ASG is using the correct launch template
  - ASG is attached to target group "CapiRentals-TG"
  - ASG has desired/minimum/maximum capacity: 1/1/4
  - Target tracking scaling policy is configured
  
  **Expected Result:**
  - Auto Scaling Groups list shows the new ASG
  - ASG details show 1 instance launching (or in service)
  - Activity history shows instance launch events
  - Target group shows registered instance(s)
  
  **Troubleshooting Tips:**
  - If instances fail to launch, check the launch template configuration
  - If instances launch but don't pass health checks, check the User Data script
  - If ASG can't attach to target group, verify both exist in the same VPC
  - Check CloudWatch logs for instance startup issues
  
  **Portuguese Terms:**
  - Grupo de Auto Scaling (Auto Scaling Group)
  - Capacidade desejada (Desired capacity)
  - Política de dimensionamento (Scaling policy)
  - Rastreamento de destino (Target tracking)

---

### Phase 4: Verification

- [ ] 11. Verify Instance Deployment and Health
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 10 (ASG created)
  
  **Objective:** Verify that EC2 instances are running, healthy, and properly registered with the load balancer.
  
  **Instructions:**
  1. Check Auto Scaling Group status:
     - Navigate to EC2 > Auto Scaling Groups
     - Click on `CapiRentals-ASG`
     - Check **Activity tab** (Atividade) for instance launch events
     - Check **Instance management tab** (Gerenciamento de instâncias)
     - Verify instance status shows "Healthy" (Saudável)
  
  2. Check EC2 instances:
     - Navigate to EC2 > Instances
     - Filter by tag: `Name = CapiRentals-Server`
     - Verify:
       - **Instance state**: Running (Em execução)
       - **Status check**: 2/2 checks passed
       - **Security group**: CapiRentals-EC2-SG
       - **IAM role**: EC2-DynamoDB-CloudWatch-Role
  
  3. Check Target Group health:
     - Navigate to EC2 > Target Groups
     - Click on `CapiRentals-TG`
     - Check **Targets tab** (Destinos)
     - Verify registered instances show:
       - **Status**: healthy (saudável) - shown in green
       - **Port**: 80
       - If status is "initializing" or "unhealthy", wait 1-2 minutes
  
  4. Check Load Balancer status:
     - Navigate to EC2 > Load Balancers
     - Click on `CapiRentals-ALB`
     - Verify **State**: Active (Ativo)
     - Check **Target Groups** tab shows healthy targets
  
  **Verification Criteria:**
  - At least 1 EC2 instance is running
  - Instance status checks show 2/2 passed
  - Target group shows instance(s) as "healthy"
  - Load balancer state is "Active"
  
  **Expected Result:**
  - Auto Scaling Group shows 1 healthy instance
  - Target Group shows healthy targets
  - No errors in activity history
  
  **Troubleshooting Tips:**
  - If instances are "unhealthy":
    - Check security group rules allow ALB to EC2 traffic
    - Check User Data script executed successfully (check instance logs)
    - Verify the server binary was downloaded and has execute permissions
  - If instances fail to launch:
    - Check ASG activity history for error messages
    - Verify launch template has correct AMI and instance type
    - Check IAM role permissions
  
  **Portuguese Terms:**
  - Instância (Instance)
  - Saudável (Healthy)
  - Verificação de status (Status check)
  - Em execução (Running)

- [ ] 12. Test Application Endpoints (/health and /calc)
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 11 (Instances verified healthy)
  
  **Objective:** Test that the application is responding correctly to HTTP requests.
  
  **Instructions:**
  1. Get the Load Balancer DNS name:
     - Navigate to EC2 > Load Balancers
     - Click on `CapiRentals-ALB`
     - Copy the **DNS name** from the Description tab
     - Example: `CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com`
  
  2. Test the /health endpoint:
     - **Option A - Browser:**
       - Open a web browser
       - Navigate to: `http://<ALB-DNS-NAME>/health`
       - Example: `http://CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com/health`
     
     - **Option B - Command Line:**
       ```bash
       curl http://<ALB-DNS-NAME>/health
       ```
   
     - **Expected Response:** `{"status": "healthy"}` or similar success message
  
  3. Test the /calc endpoint:
     - **Browser or curl:**
       - `http://<ALB-DNS-NAME>/calc`
     - **Expected Response:** Hash calculation result or client key response
  
  4. Test the root endpoint:
     - `http://<ALB-DNS-NAME>/`
     - **Expected Response:** Server information or welcome message
  
  5. Run the test script (from your local machine):
     - Edit the test script to set the BASE_URL:
       ```bash
       export BASE_URL=<ALB-DNS-NAME>
       ./test_requests.sh
       ```
     - Or run directly:
       ```bash
       BASE_URL=<ALB-DNS-NAME> ./test_requests.sh
       ```
  
  **Verification Criteria:**
  - /health endpoint returns successful response
  - /calc endpoint returns hash result
  - Application responds within reasonable time (< 2 seconds)
  - No HTTP 5xx errors
  
  **Expected Result:**
  - Browser shows JSON response for health check
  - Test script completes without errors
  - All endpoints return HTTP 200 status
  
  **Troubleshooting Tips:**
  - If you get HTTP 502/503 errors:
    - Check target group health status
    - Verify server is running on instance (check system logs)
    - Check security group allows traffic from ALB to EC2
  - If connection times out:
    - Verify ALB security group allows inbound HTTP
    - Check ALB is in public subnets with internet gateway
  - If /health returns errors:
    - SSH into instance and check server logs: `journalctl -u capirentals -f`
    - Verify DynamoDB table exists and is accessible
  
  **Portuguese Terms:**
  - Ponto de extremidade (Endpoint)
  - Tempo limite (Timeout)
  - Resposta (Response)

- [ ] 13. Configure CloudWatch Monitoring and Alarms
  - **Type:** Required
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 11 (Instances verified)
  
  **Objective:** Set up CloudWatch alarms to monitor system health and performance.
  
  **Instructions:**
  1. Navigate to CloudWatch:
     - In AWS Console search bar, type "CloudWatch"
     - Click on "CloudWatch"
  
  2. Create CPU High Alarm:
     - In left sidebar, click "Alarms" > "All alarms" (Todos os alarmes)
     - Click "Create alarm" (Criar alarme)
     - Click "Select metric" (Selecionar métrica)
     - Navigate to: EC2 > By Auto Scaling Group
     - Select `CapiRentals-ASG` > CPUUtilization
     - Click "Select metric"
     - Configure:
       - **Statistic**: Average
       - **Period**: 1 minute
       - **Threshold type**: Static
       - **Condition**: Greater than or equal to
       - **Than**: 80
     - Click "Next"
     - Configure actions (skip for now or configure SNS):
       - Click "Next"
     - **Alarm name**: `CapiRentals-HighCPU-Alarm`
     - **Description**: `Alarm when CPU exceeds 80% for 2 consecutive periods`
     - Click "Next" > "Create alarm"
  
  3. Create Target Response Time Alarm:
     - Click "Create alarm"
     - Click "Select metric"
     - Navigate to: Application ELB > Target Group, Metric
     - Select your target group
     - Select `TargetResponseTime`
     - Click "Select metric"
     - Configure:
       - **Statistic**: Average
       - **Period**: 1 minute
       - **Threshold**: Greater than 2 seconds
     - **Alarm name**: `CapiRentals-HighResponseTime-Alarm`
     - Click through to create
  
  4. Create Target Health Alarm:
     - Click "Create alarm"
     - Click "Select metric"
     - Navigate to: Application ELB > Target Group
     - Select your target group
     - Select `UnHealthyHostCount`
     - **Threshold**: Greater than or equal to 1
     - **Alarm name**: `CapiRentals-UnhealthyTargets-Alarm`
     - Click through to create
  
  5. View Dashboard:
     - Navigate to CloudWatch > Dashboards
     - Create a dashboard for CapiRentals:
       - Click "Create dashboard"
       - **Name**: `CapiRentals-Dashboard`
       - Add widgets for:
         - CPU Utilization
         - Request Count
         - Target Response Time
         - Healthy Host Count
  
  **Verification Criteria:**
  - Three alarms created: HighCPU, HighResponseTime, UnhealthyTargets
  - Alarms show "OK" status (green)
  - Dashboard displays metrics widgets
  - Metrics are being collected from instances
  
  **Expected Result:**
  - CloudWatch Alarms list shows all alarms in "OK" state
  - Dashboard shows real-time metrics
  - No missing data points in metrics
  
  **Troubleshooting Tips:**
  - If alarms show "Insufficient data":
    - Wait 5 minutes for metrics to populate
    - Verify instances are running and healthy
    - Check CloudWatch agent is running on instances
  - If you can't find specific metrics:
    - Verify ASG has group metrics enabled
    - Check instance IAM role has CloudWatch permissions
  
  **Portuguese Terms:**
  - Alarme (Alarm)
  - Métrica (Metric)
  - Painel (Dashboard)
  - Limite (Threshold)

---

### Phase 5: Testing and Optimization

- [ ] 14. Run Load Test with test_requests.sh
  - **Type:** Required
  - **Time Estimate:** 10 minutes
  - **Dependencies:** Task 12 (Application tested)
  
  **Objective:** Run the provided test script to simulate load and verify application stability.
  
  **Instructions:**
  1. Prepare the test script:
     - Ensure you have the test script: `test_requests.sh` in your workspace
     - Open a terminal/command prompt on your local machine
     - Navigate to the project directory: `cd workshop-wsc-2024`
  
  2. Set the BASE_URL:
     ```bash
     export BASE_URL=<your-alb-dns-name>
     # Example:
     export BASE_URL=CapiRentals-ALB-1234567890.us-east-1.elb.amazonaws.com
     ```
  
  3. Make the script executable (if needed):
     ```bash
     chmod +x test_requests.sh
     ```
  
  4. Run the test:
     ```bash
     ./test_requests.sh
     ```
  
  5. Monitor the results:
     - Watch for HTTP response codes (should be 200)
     - Note response times
     - Check for any errors or timeouts
  
  6. Monitor AWS Console during test:
     - Navigate to CloudWatch Dashboard
     - Watch CPU utilization increase
     - Observe request count metrics
     - Check if auto-scaling triggers (CPU should increase)
  
  7. Run multiple iterations (optional):
     ```bash
     # Run test multiple times
     for i in {1..10}; do ./test_requests.sh; done
     ```
  
  **Verification Criteria:**
  - Test script completes successfully
  - All requests return HTTP 200
  - Response times are reasonable (< 1 second average)
  - No connection errors or timeouts
  
  **Expected Result:**
  - Test output shows successful requests
  - CloudWatch metrics show increased activity
  - Application remains healthy during load
  
  **Troubleshooting Tips:**
  - If requests fail:
    - Verify BASE_URL is correct (without http://)
    - Check ALB and instances are still healthy
    - Review CloudWatch logs for errors
  - If response times are slow:
    - Check instance type (may need larger)
    - Verify database queries are efficient
  - If connection refused:
    - Verify ALB DNS name is correct
    - Check security groups allow traffic
  
  **Portuguese Terms:**
  - Teste de carga (Load test)
  - Tempo de resposta (Response time)
  - Executável (Executable)

- [ ] 15. Verify Auto-Scaling Behavior
  - **Type:** Optional (Recommended)
  - **Time Estimate:** 15 minutes
  - **Dependencies:** Task 14 (Load test completed)
  
  **Objective:** Verify that auto-scaling responds correctly to increased load.
  
  **Instructions:**
  1. Generate sustained load:
     - Run the test script in multiple terminals or loops
     - Use a load testing tool like `hey` or `ab` (Apache Bench)
     - Example with curl loop:
       ```bash
       while true; do curl http://<ALB-DNS>/calc; done
       ```
  
  2. Monitor CloudWatch metrics:
     - Navigate to CloudWatch > Dashboards
     - Watch CPU utilization rise
     - Target tracking policy should trigger scale-out at 70% CPU
  
  3. Check ASG activities:
     - Navigate to EC2 > Auto Scaling Groups
     - Click on `CapiRentals-ASG`
     - Monitor **Activity tab**:
       - Look for "Launching a new EC2 instance" message
       - Note the scaling policy that triggered the action
  
  4. Verify new instances:
     - Navigate to EC2 > Instances
     - Count the number of running instances
     - Should see additional instances launching
  
  5. Wait for scale-in (cooldown):
     - Stop the load test
     - Wait for CPU to drop below threshold
     - Observe if ASG scales in (terminates instances)
     - Note: Scale-in is disabled if you selected that option
  
  **Verification Criteria:**
  - CPU utilization increases under load
  - ASG triggers scaling activities
  - New instances launch when CPU > 70%
  - Activity history shows scaling events
  
  **Expected Result:**
  - Under sustained load, ASG launches additional instances
  - Scale-out activities are recorded in ASG history
  - Target tracking policy maintains CPU near target
  
  **Troubleshooting Tips:**
  - If scaling doesn't trigger:
    - Verify scaling policy is configured
    - Check target value (70% may be too high for your load)
    - Ensure CloudWatch metrics are being published
  - If instances launch but fail health checks:
    - Check User Data script
    - Verify security group configuration
    - Review instance system logs
  
  **Portuguese Terms:**
  - Dimensionamento automático (Auto scaling)
  - Escalar horizontalmente (Scale out)
  - Escalar verticalmente (Scale in)
  - Política de rastreamento de destino (Target tracking policy)

- [ ] 16. Cost Verification and Cleanup
  - **Type:** Optional (Recommended)
  - **Time Estimate:** 10 minutes
  - **Dependencies:** All previous tasks completed
  
  **Objective:** Review costs and understand cleanup procedures.
  
  **Instructions:**
  1. Review Learner Lab budget:
     - Return to the Learner Lab interface
     - Check remaining credits/budget
     - Note the estimated cost of resources
  
  2. Estimate monthly costs (if running continuously):
     - **EC2 instances**: t2.micro ~$8.50/month per instance
     - **Application Load Balancer**: ~$16/month + $0.008 per LCU-hour
     - **DynamoDB**: On-demand pricing ~$1.25 per million write units
     - **CloudWatch**: ~$0.30 per metric/month
     - **Data transfer**: First 100GB/month free
     - **Estimated total**: ~$25-40/month with 1-2 instances
  
  3. Cost optimization tips:
     - Use Spot Instances for non-critical workloads (up to 90% savings)
     - Consider Reserved Instances for long-running workloads
     - Right-size instances based on actual utilization
     - Delete unused resources
  
  4. Cleanup procedure (when done):
     - **Delete ASG:**
       - Navigate to EC2 > Auto Scaling Groups
       - Select `CapiRentals-ASG`
       - Click "Delete" (Excluir)
       - Confirm deletion
     
     - **Delete Load Balancer:**
       - Navigate to EC2 > Load Balancers
       - Select `CapiRentals-ALB`
       - Click "Actions" > "Delete load balancer"
       - Confirm
     
     - **Delete Target Group:**
       - Navigate to EC2 > Target Groups
       - Select `CapiRentals-TG`
       - Click "Delete"
     
     - **Delete Launch Template:**
       - Navigate to EC2 > Launch Templates
       - Select `CapiRentals-Launch-Template`
       - Click "Actions" > "Delete template"
     
     - **Delete Security Groups:**
       - Navigate to VPC > Security Groups
       - Delete `CapiRentals-EC2-SG` first
       - Delete `CapiRentals-ALB-SG`
     
     - **Delete IAM Role:**
       - Navigate to IAM > Roles
       - Select `EC2-DynamoDB-CloudWatch-Role`
       - Click "Delete"
     
     - **Delete DynamoDB Table:**
       - Navigate to DynamoDB > Tables
       - Select `CapiRentalsHash`
       - Click "Delete"
       - Type "delete" to confirm
  
  **Verification Criteria:**
  - Budget usage is within limits
  - Understanding of cost components
  - Cleanup procedure documented for future reference
  
  **Expected Result:**
  - Clear understanding of resource costs
  - All resources can be deleted when no longer needed
  - Lab budget remains positive
  
  **Troubleshooting Tips:**
  - If security groups fail to delete:
    - Check for dependent resources (instances, load balancers)
    - Delete dependent resources first
  - If IAM role fails to delete:
    - Detach from EC2 instances first
    - Remove all policies before deletion
  
  **Portuguese Terms:**
  - Custo (Cost)
  - Orçamento (Budget)
  - Excluir (Delete)
  - Limpeza (Cleanup)

---

## Notes

- **Time estimates** are approximate for beginners; experienced users may complete tasks faster
- **Portuguese translations** are provided for key AWS Console terms to assist Portuguese-speaking users
- **Troubleshooting tips** address common issues encountered in AWS Learner Lab environments
- **Security group configuration** follows the principle of least privilege (ALB accessible from internet, EC2 only from ALB)
- **User Data script** includes systemd service configuration for automatic restarts
- **Auto Scaling configuration** allows scaling from 1-4 instances based on CPU utilization
- **CloudWatch alarms** are configured without SNS notifications; add SNS topics if you want email/SMS alerts

**Important Reminders:**
1. AWS Learner Lab has resource limitations and budget constraints
2. Always clean up resources when finished to preserve credits
3. The application is stateless, making horizontal scaling straightforward
4. Keep the ALB DNS name handy for testing and verification

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "2", "3"] },
    { "id": 1, "tasks": ["4", "7"] },
    { "id": 2, "tasks": ["5", "6"] },
    { "id": 3, "tasks": ["8", "9"] },
    { "id": 4, "tasks": ["10"] },
    { "id": 5, "tasks": ["11"] },
    { "id": 6, "tasks": ["12", "13"] },
    { "id": 7, "tasks": ["14"] },
    { "id": 8, "tasks": ["15", "16"] }
  ]
}
```

---

## Summary

**Total Estimated Time:** 2.5 - 3 hours for a beginner

**Task Breakdown:**
- Phase 1 (Preparation): 25 minutes
- Phase 2 (Network Infrastructure): 50 minutes
- Phase 3 (Compute Infrastructure): 45 minutes
- Phase 4 (Verification): 35 minutes
- Phase 5 (Testing and Optimization): 35 minutes

**Critical Path:**
1. AWS access → DynamoDB table + IAM role (parallel)
2. VPC configuration → Security groups (parallel with subnets)
3. Subnets + IGW + Route tables → Launch template + ALB
4. Auto Scaling Group → Verification
5. Testing → Optimization

**Success Criteria:**
- Application accessible via ALB DNS name
- /health endpoint returns healthy status
- /calc endpoint returns valid hash results
- Auto Scaling Group maintains at least 1 healthy instance
- CloudWatch metrics are being collected
- Load test completes without errors

**Next Steps After Completion:**
1. Monitor application performance over time
2. Adjust scaling policies based on actual traffic patterns
3. Configure additional CloudWatch alarms as needed
4. Consider implementing blue-green deployments for updates
5. Document any issues encountered for future reference