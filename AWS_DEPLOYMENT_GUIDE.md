# Guia Completo de Deploy AWS para WorldSkills Cloud Computing
# Complete AWS Deployment Guide for WorldSkills Cloud Computing

> **Para competidores iniciantes em AWS** | **For competitors new to AWS**
> 
> Este guia explica cada conceito desde o básico, conectando teoria à prática.
> This guide explains each concept from the ground up, connecting theory to practice.

---

## 📋 Índice | Table of Contents

1. [Entendendo o Desafio | Understanding the Challenge](#1-entendendo-o-desafio)
2. [Arquitetura Explicada | Architecture Explained](#2-arquitetura-explicada)
3. [Conceitos Fundamentais AWS | Core AWS Concepts](#3-conceitos-fundamentais-aws)
4. [Guia Passo a Passo | Step-by-Step Guide](#4-guia-passo-a-passo)
5. [Otimização de Custos | Cost Optimization](#5-otimização-de-custos)
6. [Troubleshooting](#6-troubleshooting)
7. [Conceitos Avançados | Advanced Concepts](#7-conceitos-avançados)

---

## 1. Entendendo o Desafio | Understanding the Challenge

### O que você precisa implantar | What You Need to Deploy

Uma aplicação Go (Capi's Rentals) que:
- Fornece hashes criptográficos como serviço
- Tem 2 endpoints: `/health` e `/calc?input=value`
- Usa DynamoDB para armazenamento
- Precisa escalar automaticamente conforme o tráfego

A Go application (Capi's Rentals) that:
- Provides cryptographic hash services
- Has 2 endpoints: `/health` and `/calc?input=value`
- Uses DynamoDB for storage
- Needs to automatically scale with traffic

### Analogia: O Restaurante | Analogy: The Restaurant

Imagine que você está montando um **restaurante**:

| Componente da Nuvem | Analogia do Restaurante |
|---------------------|------------------------|
| **VPC** | O terreno onde o restaurante será construído |
| **Subnet** | As diferentes áreas (cozinha, salão, área externa) |
| **EC2 Instance** | Um funcionário atendendo clientes |
| **Auto Scaling** | Contratar mais funcionários quando está cheio, demitir quando está vazio |
| **Load Balancer** | O gerente que direciona clientes para funcionários disponíveis |
| **DynamoDB** | O sistema de pedidos (caderno) que guarda informações |
| **CloudWatch** | Câmeras de segurança e relatórios de desempenho |
| **CloudFront** | Um garçom extra na porta que atende clientes rapidamente |

---

## 2. Arquitetura Explicada | Architecture Explained

### Diagrama da Arquitetura | Architecture Diagram

```
                                    ┌─────────────────────┐
                                    │      INTERNET       │
                                    │   (Usuários/Web)    │
                                    └──────────┬──────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │    CLOUDFRONT       │ ← CDN: Cache na borda
                                    │  (Distribuição)     │   Cache at the edge
                                    └──────────┬──────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │   APPLICATION       │
                                    │   LOAD BALANCER     │ ← Distribui tráfego
                                    │      (ALB)          │   Distributes traffic
                                    └──────────┬──────────┘
                                               │
                          ┌────────────────────┼────────────────────┐
                          │                    │                    │
                          ▼                    ▼                    ▼
                   ┌────────────┐      ┌────────────┐      ┌────────────┐
                   │   EC2 #1   │      │   EC2 #2   │      │   EC2 #N   │
                   │ (Servidor) │      │ (Servidor) │      │ (Servidor) │ ← Instâncias
                   │  App Go    │      │  App Go    │      │  App Go    │
                   └─────┬──────┘      └─────┬──────┘      └─────┬──────┘
                         │                   │                   │
                         └───────────────────┼───────────────────┘
                                             │
                                             ▼
                                    ┌─────────────────────┐
                                    │     DYNAMODB        │ ← Banco de dados
                                    │   (Tabela: Hash)    │   Database
                                    └─────────────────────┘
                                             │
                                             ▼
                                    ┌─────────────────────┐
                                    │    CLOUDWATCH       │ ← Monitoramento
                                    │  (Alarmes/Métricas) │   Monitoring
                                    └─────────────────────┘
```

### Por que esta arquitetura? | Why This Architecture?

| Serviço | Por que precisamos? | What it does |
|---------|---------------------|--------------|
| **VPC** | Isola seus recursos como uma rede privada virtual | Creates a private network for your resources |
| **Subnet** | Divide a VPC em zonas públicas e privadas | Divides VPC into public/private zones |
| **EC2** | Executa a aplicação Go | Runs your Go application |
| **Auto Scaling** | Adiciona/remove servidores automaticamente | Automatically adds/removes servers |
| **ALB** | Distribui tráfego entre servidores | Distributes traffic among servers |
| **DynamoDB** | Armazena os hashes calculados | Stores calculated hashes |
| **CloudWatch** | Monitora saúde e performance | Monitors health and performance |
| **CloudFront** | Cache estático para respostas rápidas | Static cache for fast responses |

---

## 3. Conceitos Fundamentais AWS | Core AWS Concepts

### 3.1 VPC (Virtual Private Cloud)

**O que é? | What is it?**

Imagine que você está construindo uma casa. A VPC é o **terreno** onde tudo será construído. É sua rede privada na nuvem AWS.

Think of building a house. A VPC is the **land** where everything will be built. It's your private network in AWS cloud.

**Por que precisamos? | Why do we need it?**

- Segurança: isola seus recursos da internet pública
- Controle: você define quem pode entrar e sair
- Organização: permite dividir em sub-redes (subnets)

```
┌─────────────────────────────────────────────────────────┐
│                         VPC                              │
│  (Sua rede privada | Your private network)              │
│                                                          │
│   ┌──────────────────┐    ┌──────────────────┐         │
│   │   Subnet Pública  │    │  Subnet Privada  │         │
│   │  (Public Subnet)  │    │ (Private Subnet) │         │
│   │                   │    │                  │         │
│   │  - Load Balancer  │    │  - EC2 Instances │         │
│   │  - NAT Gateway    │    │  - DynamoDB      │         │
│   │                   │    │                  │         │
│   └──────────────────┘    └──────────────────┘         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Componentes importantes | Important Components:**

1. **CIDR Block**: O "endereço" da sua rede (ex: 10.0.0.0/16)
2. **Internet Gateway**: A "porta de entrada" da internet
3. **Route Tables**: Define por onde os dados saem

### 3.2 Subnets (Sub-redes)

**O que é? | What is it?**

Uma subnet é uma **divisão** da VPC. Como quartos em uma casa, cada subnet tem uma função específica.

A subnet is a **division** of the VPC. Like rooms in a house, each subnet has a specific function.

**Tipos de Subnets | Types of Subnets:**

| Tipo | Pode acessar internet? | Uso típico |
|------|------------------------|------------|
| **Pública** | Sim (via Internet Gateway) | Load Balancers, NAT Gateway |
| **Privada** | Não diretamente | EC2 com aplicação, bancos de dados |

**Por que usar Availability Zones (AZs)? | Why use Availability Zones?**

AWS tem múltiplos data centers em cada região. Cada AZ é um data center diferente. Usar 2+ AZs garante que se um data center cair, sua aplicação continua funcionando.

AWS has multiple data centers in each region. Each AZ is a different data center. Using 2+ AZs ensures if one data center fails, your application keeps running.

### 3.3 Security Groups e NACLs

**O que são? | What are they?**

São **firewalls** que controlam quem pode entrar e sair dos seus servidores.

They are **firewalls** that control who can enter and leave your servers.

**Security Group (SG):**
- Firewall no nível do servidor (EC2)
- Stateful: se você permite saída, a resposta é automaticamente permitida
- Regras: entrada (inbound) e saída (outbound)

**Network ACL (NACL):**
- Firewall no nível da subnet
- Stateless: você precisa permitir entrada E saída explicitamente
- Processado em ordem numérica

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET                              │
│                         │                                │
│                         ▼                                │
│              ┌─────────────────────┐                    │
│              │    Network ACL      │ ← Primeira barreira │
│              │    (Subnet Level)   │   First barrier     │
│              └──────────┬──────────┘                    │
│                         │                                │
│                         ▼                                │
│              ┌─────────────────────┐                    │
│              │  Security Group     │ ← Segunda barreira │
│              │  (Instance Level)    │   Second barrier   │
│              └──────────┬──────────┘                    │
│                         │                                │
│                         ▼                                │
│              ┌─────────────────────┐                    │
│              │    EC2 Instance      │                    │
│              │   (Seu Servidor)     │                    │
│              └─────────────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### 3.4 EC2 (Elastic Compute Cloud)

**O que é? | What is it?**

Um **servidor virtual** na nuvem. É como alugar um computador que está rodando em algum lugar do mundo.

A **virtual server** in the cloud. Like renting a computer running somewhere in the world.

**Componentes | Components:**

1. **AMI (Amazon Machine Image)**: O "sistema operacional + software" pré-instalado
2. **Instance Type**: O "tamanho" do servidor (CPU, memória)
3. **Storage (EBS)**: O "disco rígido" do servidor

**Instance Types para este projeto | Instance Types for this project:**

| Tipo | vCPUs | Memória | Custo/hora | Uso |
|------|-------|---------|------------|-----|
| t2.micro | 1 | 1 GB | ~$0.0116 | Desenvolvimento |
| t3.micro | 2 | 1 GB | ~$0.0104 | Recomendado para competição |
| t3.small | 2 | 2 GB | ~$0.0208 | Se precisar de mais memória |

### 3.5 Load Balancer (Application Load Balancer - ALB)

**O que é? | What is it?**

Um **distribuidor de tráfego**. Imagine um gerente de restaurante que direciona clientes para garçons disponíveis.

A **traffic distributor**. Imagine a restaurant manager directing customers to available waiters.

**Como funciona | How it works:**

1. Recebe requisições da internet
2. Verifica quais EC2 estão saudáveis (health checks)
3. Distribui a requisição para um EC2 saudável
4. Retorna a resposta ao cliente

```
         Requisições
             │
             ▼
    ┌────────────────┐
    │     ALB        │ ← Health checks nos EC2s
    │ Load Balancer  │
    └────────┬───────┘
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
 ┌────┐  ┌────┐  ┌────┐
 │EC2 │  │EC2 │  │EC2 │
 │ #1 │  │ #2 │  │ #3 │
 └────┘  └────┘  └────┘
```

**Por que é essencial? | Why is it essential?**

- **High Availability**: Se um servidor cai, o tráfego vai para outros
- **Scaling**: Funciona com Auto Scaling para adicionar/remover servidores
- **Health Checks**: Remove servidores não-saudáveis automaticamente

### 3.6 Auto Scaling Groups (ASG)

**O que é? | What is it?**

Um **gerente automático** de servidores. Adiciona servidores quando a demanda aumenta e remove quando diminui.

An **automatic manager** of servers. Adds servers when demand increases and removes when it decreases.

**Como funciona | How it works:**

```
┌─────────────────────────────────────────────────────────┐
│                 AUTO SCALING GROUP                       │
│                                                          │
│   Mínimo: 1 instância     ─────────────────────────────  │
│   Desejado: 2 instâncias  (configurável)                 │
│   Máximo: 4 instâncias    ─────────────────────────────  │
│                                                          │
│   Scaling Policies:                                      │
│   • CPU > 70% → Adicionar 1 instância                    │
│   • CPU < 30% → Remover 1 instância                      │
│                                                          │
│   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐               │
│   │ EC2  │  │ EC2  │  │ EC2  │  │ EC2  │               │
│   │  #1  │  │  #2  │  │  #3  │  │  #4  │               │
│   └──────┘  └──────┘  └──────┘  └──────┘               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Launch Template | Launch Template:**

É a **receita** para criar novas instâncias EC2:
- Qual AMI usar
- Qual tipo de instância
- Security Groups
- Script de inicialização (User Data)

### 3.7 DynamoDB

**O que é? | What is it?**

Um banco de dados **NoSQL** totalmente gerenciado. Pense como uma tabela de Excel super poderosa na nuvem.

A fully managed **NoSQL** database. Think of it as a super powerful Excel table in the cloud.

**Estrutura | Structure:**

```
┌─────────────────────────────────────────────┐
│           Tabela: HashResults               │
├─────────────────┬─────────────┬──────────────┤
│   id (PK)       │   Texto     │  base64_hash │
├─────────────────┼─────────────┼──────────────┤
│ abc123...       │ "hello"     │ "aGVsbG8="   │
│ def456...       │ "world"     │ "d29ybGQ="   │
└─────────────────┴─────────────┴──────────────┘
```

**Por que DynamoDB e não RDS? | Why DynamoDB not RDS?**

| Critério | DynamoDB | RDS |
|----------|----------|-----|
| Escala | Ilimitada, automática | Manual ou limitada |
| Manutenção | Zero | Backup, patches, etc |
| Latência | Milissegundos | Variável |
| Modelo | NoSQL (flexível) | Relacional (estruturado) |
| Custo | Por uso | Por hora |

Para nossa aplicação, DynamoDB é perfeito porque:
- Escala automaticamente com o tráfego
- Não precisa de manutenção
- Baixa latência para leituras/escritas

### 3.8 CloudWatch

**O que é? | What is it?**

O **sistema de monitoramento** da AWS. Como um painel de controle de carro que mostra velocidade, combustível, temperatura.

AWS's **monitoring system**. Like a car dashboard showing speed, fuel, temperature.

**O que você pode fazer | What you can do:**

1. **Métricas**: CPU, memória, tráfego de rede
2. **Logs**: Mensagens da aplicação
3. **Alarmes**: Alertas quando algo está errado
4. **Dashboards**: Visualização gráfica

```
┌─────────────────────────────────────────────────────────┐
│                 CLOUDWATCH DASHBOARD                     │
│                                                          │
│  ┌─────────────────┐    ┌─────────────────┐            │
│  │  CPU Usage      │    │  Request Count   │            │
│  │  ████████░░ 80% │    │  ██████░░░░ 60%  │            │
│  └─────────────────┘    └─────────────────┘            │
│                                                          │
│  ┌─────────────────────────────────────────────┐        │
│  │  ALARM: CPU > 80% for 5 minutes             │        │
│  │  Action: Scale Out (+1 instance)            │        │
│  └─────────────────────────────────────────────┘        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 3.9 CloudFront

**O que é? | What is it?**

Uma **CDN (Content Delivery Network)**. Imagine ter cópias do seu restaurante em várias cidades - clientes vão ao mais próximo.

A **CDN (Content Delivery Network)**. Imagine having copies of your restaurant in multiple cities - customers go to the nearest one.

**Como funciona para nossa aplicação | How it works for our app:**

1. Cache de respostas HTTP nos Edge Locations
2. Para `/health`: pode retornar resposta cached (muito rápido)
3. Para `/calc`: pode não ser ideal (cada input é único)

**Consideração | Consideration:**

Para este desafio, CloudFront é **opcional**. O endpoint `/calc` gera hashes únicos, então cache não ajuda muito. O `/health` pode se beneficiar de cache.

---

## 4. Guia Passo a Passo | Step-by-Step Guide

### Pré-requisitos | Prerequisites

1. ✅ Acesso ao AWS Learner Lab
2. ✅ Créditos disponíveis (50 créditos)
3. ✅ Navegador web

---

### PASSO 1: Iniciar o Lab | Start the Lab

1. Acesse o **AWS Academy Learner Lab**
2. Clique em **"Start Lab"** (botão verde à direita)
3. Aguarde até que o status mude para **"Lab is ready"** (indicador verde)
4. Clique em **"AWS"** (link azul) para abrir o Console AWS

> ⚠️ **IMPORTANTE**: O Lab tem limite de tempo! Monitore o contador no canto superior direito.

---

### PASSO 2: Criar a Tabela DynamoDB | Create DynamoDB Table

**Por que primeiro?** A aplicação precisa da tabela para funcionar. Criar primeiro evita erros.

#### 2.1 Navegar para DynamoDB

1. No Console AWS, digite **"DynamoDB"** na barra de busca
2. Clique em **DynamoDB** (serviço)

#### 2.2 Criar Tabela | Create Table

1. Clique em **"Create table"**
2. Preencha os campos:

| Campo | Valor |
|-------|-------|
| Table name | `CapiRentalsHash` |
| Partition key | `id` (String) |

3. Em **Table settings**, escolha **"Customize settings"**
4. Em **Capacity mode**, selecione:
   - **"Provisioned"** para controle de custos
   - **"On-demand"** se preferir simplicidade (custo maior em alto tráfego)

> 💡 **DICA DE CUSTO**: Para o Learner Lab com tráfego limitado, **On-demand** é mais simples. Para produção, **Provisioned com Auto Scaling** é mais econômico.

5. Clique **"Create table"**

#### 2.3 Verificar Criação

1. Aguarde o status mudar para **"Active"** (alguns segundos)
2. Anote o nome da tabela: `CapiRentalsHash`

---

### PASSO 3: Criar VPC | Create VPC

> 📝 **NOTA**: O Learner Lab pode ter uma VPC padrão. Verifique primeiro!

#### 3.1 Verificar VPC Existente

1. Digite **"VPC"** na busca
2. Clique em **VPC**
3. No menu esquerdo, clique em **"Your VPCs"**
4. Se existir uma VPC com nome "Default" ou similar, você pode usá-la

#### 3.2 Criar Nova VPC (se necessário)

1. Clique em **"Create VPC"**
2. Escolha **"VPC and more"** (recomendado - cria tudo automaticamente)
3. Preencha:

| Campo | Valor |
|-------|-------|
| Name tag auto-generation | `capirentals` |
| Number of AZs | `2` (para alta disponibilidade) |
| Number of public subnets | `2` |
| Number of private subnets | `0` (não precisamos para este caso) |
| NAT gateways | `None` (economia de custos) |
| VPC endpoints | `None` |

> 💡 **SIMPLIFICAÇÃO**: Para este desafio, vamos usar **subnets públicas** para as instâncias EC2, já que não há dados sensíveis e isso economiza custos de NAT Gateway.

4. Clique em **"Create VPC"**

#### 3.3 Verificar Recursos Criados

O AWS criará automaticamente:
- 1 VPC
- 2 Subnets públicas (em 2 AZs diferentes)
- 1 Internet Gateway
- 2 Route Tables
- Security Groups

---

### PASSO 4: Criar Security Group | Create Security Group

**O que fazemos aqui?** Permitir tráfego HTTP na porta 80 (ou porta da aplicação).

#### 4.1 Navegar para Security Groups

1. No Console VPC, menu esquerdo
2. Clique em **"Security Groups"**
3. Clique em **"Create security group"**

#### 4.2 Configurar Security Group

| Campo | Valor |
|-------|-------|
| Security group name | `capirentals-sg` |
| Description | `Security group for Capi's Rentals application` |
| VPC | Selecione a VPC criada (ou padrão) |

#### 4.3 Adicionar Regras de Entrada (Inbound Rules)

Clique em **"Add rule"** duas vezes:

| Type | Protocol | Port | Source | Descrição |
|------|----------|------|--------|-----------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Allow HTTP from internet |
| SSH | TCP | 22 | Seu IP | Admin access (opcional) |

> ⚠️ **SEGURANÇA**: Em produção, NUNCA deixe SSH aberto para 0.0.0.0/0. Use seu IP específico ou AWS Systems Manager Session Manager.

#### 4.4 Regras de Saída (Outbound Rules)

Mantenha o padrão: **Allow all traffic (0.0.0.0/0)**

A aplicação precisa sair para:
- DynamoDB
- CloudWatch
- Internet (para downloads se necessário)

#### 4.5 Criar

Clique em **"Create security group"**

---

### PASSO 5: Criar Launch Template | Create Launch Template

**Por que Launch Template e não Launch Configuration?**
Launch Template é mais moderno e recomendado pela AWS.

#### 5.1 Navegar para EC2

1. Digite **"EC2"** na busca
2. Clique em **EC2**

#### 5.2 Criar Launch Template

1. No menu esquerdo, em **"Instances"**, clique em **"Launch Templates"**
2. Clique em **"Create launch template"**

#### 5.3 Configurar Launch Template

**Seção: Launch template name and tags**

| Campo | Valor |
|-------|-------|
| Launch template name | `capirentals-launch-template` |
| Template version description | `Version 1` |
| Auto Scaling guidance | ✅ Check |

**Seção: Instance type**

| Campo | Valor |
|-------|-------|
| Instance type | `t3.micro` (recomendado) ou `t2.micro` |

**Seção: Key pair (login)**

| Campo | Valor |
|-------|-------|
| Key pair | Selecione existente ou crie novo |

> 💡 **DICA**: Se não tiver key pair, clique em "Create new key pair", nomeie como "capirentals-key", baixe o arquivo .pem e guarde em local seguro.

**Seção: Network settings**

| Campo | Valor |
|-------|-------|
| Security groups | `capirentals-sg` (criado no passo 4) |

**Seção: Advanced details** ⬅️ IMPORTANTE!

| Campo | Valor |
|-------|-------|
| IAM instance profile | Selecione um que tenha permissões DynamoDB e CloudWatch |

> ⚠️ **CRÍTICO**: Se não houver IAM profile, você PRECISA criar um. Veja o Passo 5.4 abaixo.

#### 5.4 Criar IAM Role para EC2 (se necessário)

Se não houver IAM instance profile:

1. Abra uma nova aba do Console
2. Digite **"IAM"** na busca
3. Clique em **IAM**
4. No menu esquerdo, clique em **"Roles"**
5. Clique em **"Create role"**

**Passo 1: Select trusted entity**
- Service: **EC2**
- Use case: **EC2 - Allow EC2 instances to call AWS services**
- Clique em **"Next"**

**Passo 2: Add permissions**
Busque e adicione:
- `AmazonDynamoDBFullAccess` (para DynamoDB)
- `CloudWatchAgentServerPolicy` (para CloudWatch)

Clique em **"Next"**

**Passo 3: Name, review, and create**
- Role name: `capirentals-ec2-role`
- Clique em **"Create role"**

**Voltar para a Launch Template:**
- Selecione o role `capirentals-ec2-role` no campo IAM instance profile

#### 5.5 User Data Script (MUITO IMPORTANTE!)

No campo **"User data"**, cole o seguinte script:

```bash
#!/bin/bash
# Update system packages
yum update -y

# Install required packages
yum install -y aws-cli

# Set environment variables
export DYNAMO_TABLE="CapiRentalsHash"
export PORT="80"

# Download the application binary
# Option 1: From S3 (recommended)
# aws s3 cp s3://YOUR_BUCKET_NAME/server /opt/capirentals/server

# Option 2: If binary is on the instance already
# (You would need to bake it into a custom AMI)

# For Learner Lab, let's use a simple approach:
# Create the application directory
mkdir -p /opt/capirentals
cd /opt/capirentals

# Download the server binary
# Replace with actual method to get your binary
# Example using wget from a URL:
wget -O server https://github.com/thiagodavala/workshop-wsc-2024/raw/main/ami-bin/server

# Make it executable
chmod +x server

# Create systemd service file
cat > /etc/systemd/system/capirentals.service << 'EOF'
[Unit]
Description=Capi's Rentals Hash Service
After=network.target

[Service]
Type=simple
Environment="DYNAMO_TABLE=CapiRentalsHash"
Environment="PORT=80"
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

# Log success
echo "Capi's Rentals application started successfully" >> /var/log/capirentals.log
```

> 📝 **NOTA**: Este script baixa o binário do GitHub. Para produção, use S3 ou crie uma AMI customizada.

#### 5.6 Criar Launch Template

Clique em **"Create launch template"**

---

### PASSO 6: Criar Application Load Balancer (ALB)

#### 6.1 Navegar para Load Balancers

1. No Console EC2
2. Menu esquerdo, em **"Load Balancing"**
3. Clique em **"Load Balancers"**

#### 6.2 Criar Load Balancer

1. Clique em **"Create load balancer"**
2. Em Application Load Balancer, clique em **"Create"**

#### 6.3 Configurar ALB

**Seção: Basic configuration**

| Campo | Valor |
|-------|-------|
| Load balancer name | `capirentals-alb` |
| Scheme | **Internet-facing** |
| IP address type | IPv4 |

**Seção: Network mapping**

| Campo | Valor |
|-------|-------|
| VPC | Sua VPC criada |
| Mappings | Selecione **2 Availability Zones** |

**Seção: Security groups**

| Campo | Valor |
|-------|-------|
| Security groups | `capirentals-sg` (ou crie um novo para ALB) |

> 💡 **RECOMENDAÇÃO**: Criar um Security Group separado para o ALB:
> - Inbound: HTTP (80) from 0.0.0.0/0
> - Outbound: All traffic

**Seção: Listeners**

| Protocol | Port | Default action |
|----------|------|----------------|
| HTTP | 80 | Forward to target group (criar novo) |

#### 6.4 Criar Target Group

1. Na seção de Listeners, clique em **"Create target group"**

**Configurar Target Group:**

| Campo | Valor |
|-------|-------|
| Choose a target type | **Instances** |
| Target group name | `capirentals-targets` |
| Protocol | HTTP |
| Port | 80 |
| VPC | Sua VPC |
| Health check path | `/health` |
| Health check interval | 30 seconds |
| Healthy threshold | 2 |
| Unhealthy threshold | 3 |

2. Clique em **"Next"**
3. Não adicione instâncias ainda (ASG fará isso)
4. Clique em **"Create target group"**

#### 6.5 Voltar e Criar ALB

1. Volte para a criação do ALB
2. Selecione o target group criado
3. Clique em **"Create load balancer"**

#### 6.6 Anotar DNS Name

Após criar, você verá um **DNS name** como:
`capirentals-alb-123456789.us-east-1.elb.amazonaws.com`

**Guarde este endereço!** É por aqui que você acessará a aplicação.

---

### PASSO 7: Criar Auto Scaling Group (ASG)

#### 7.1 Navegar para Auto Scaling Groups

1. No Console EC2
2. Menu esquerdo, em **"Auto Scaling"**
3. Clique em **"Auto Scaling Groups"**

#### 7.2 Criar ASG

1. Clique em **"Create Auto Scaling group"**

#### 7.3 Configurar ASG - Step 1: Choose launch template or configuration

| Campo | Valor |
|-------|-------|
| Name | `capirentals-asg` |
| Launch template | `capirentals-launch-template` |
| Version | `Default` |

Clique em **"Next"**

#### 7.4 Step 2: Choose instance launch options

| Campo | Valor |
|-------|-------|
| VPC | Sua VPC |
| Availability Zones | Selecione as 2 zonas |
| Subnets | Suas 2 subnets públicas |

Clique em **"Next"**

#### 7.5 Step 3: Configure advanced options

**Load balancing:**

| Campo | Valor |
|-------|-------|
| Attach to an existing load balancer | ✅ |
| Choose a target group | `capirentals-targets` |

**Health checks:**

| Campo | Valor |
|-------|-------|
| Health check type | **ELB** (usar health check do ALB) |
| Health check grace period | 300 seconds (5 minutos para app iniciar) |

**Additional settings:**

| Campo | Valor |
|-------|-------|
| Enable group metrics collection | ✅ |

Clique em **"Next"**

#### 7.6 Step 4: Configure group size and scaling policies

**Group size:**

| Campo | Valor | Explicação |
|-------|-------|------------|
| Minimum capacity | `1` | Sempre pelo menos 1 servidor |
| Maximum capacity | `3` | Máximo de 3 servidores (economia) |
| Desired capacity | `2` | Iniciar com 2 servidores |

**Scaling policies:**

1. Selecione **"Target tracking scaling policy"**
2. Nome: `capirentals-cpu-scaling`
3. Metric type: **Average CPU utilization**
4. Target value: `70` (escala quando CPU > 70%)
5. Instance warm-up: `300` seconds

> 💡 **ECONOMIA**: Mantenha Maximum baixo (3-4) para economizar créditos.

Clique em **"Next"**

#### 7.7 Step 5: Add notifications (optional)

Você pode configurar notificações SNS para alertas, mas é opcional para este desafio.

#### 7.8 Step 6: Add tags (optional)

Adicione tags para organizar:

| Key | Value |
|-----|-------|
| Name | CapiRentals |
| Environment | Competition |
| Project | WorldSkills |

Clique em **"Next"**

#### 7.9 Review and Create

1. Revise todas as configurações
2. Clique em **"Create Auto Scaling group"**

---

### PASSO 8: Verificar Deployment | Verify Deployment

#### 8.1 Verificar Instâncias

1. No Console EC2, clique em **"Instances"**
2. Você deve ver 2 instâncias sendo criadas
3. Aguarde o status mudar para **"running"**

#### 8.2 Verificar Health Checks

1. Vá em **"Target Groups"** no menu esquerdo
2. Selecione `capirentals-targets`
3. Aba **"Targets"**
4. Aguarde as instâncias ficarem **"healthy"**

#### 8.3 Testar Aplicação

Abra um terminal e execute:

```bash
# Substitua pelo DNS do seu ALB
export BASE_URL=http://capirentals-alb-123456789.us-east-1.elb.amazonaws.com

# Teste health endpoint
curl $BASE_URL/health
# Resposta esperada: Healthy!

# Teste calc endpoint
curl "$BASE_URL/calc?input=test"
# Resposta esperada: {"base64_hash": "..."}
```

Ou use o script de testes fornecido:

```bash
export BASE_URL=http://capirentals-alb-123456789.us-east-1.elb.amazonaws.com
chmod +x test_requests.sh
./test_requests.sh
```

---

### PASSO 9: Configurar CloudWatch Monitoring | Configure CloudWatch

#### 9.1 Criar Dashboard

1. Digite **"CloudWatch"** na busca
2. Clique em **CloudWatch**
3. No menu esquerdo, clique em **"Dashboards"**
4. Clique em **"Create dashboard"**
5. Nome: `capirentals-dashboard`

#### 9.2 Adicionar Widgets

**Adicione os seguintes widgets:**

1. **Line widget - CPU Utilization:**
   - Browse: EC2 → Auto Scaling
   - Metric: `CPUUtilization`
   - Statistic: Average
   - Period: 1 minute

2. **Number widget - Request Count:**
   - Browse: Application Load Balancer
   - Metric: `RequestCount`
   - Statistic: Sum

3. **Number widget - Healthy Host Count:**
   - Browse: Application Load Balancer
   - Metric: `HealthyHostCount`
   - Statistic: Average

#### 9.3 Criar Alarmes

**Alarme 1: High CPU**

1. No menu esquerdo, clique em **"Alarms"**
2. **"All alarms"** → **"Create alarm"**
3. **Select metric:**
   - Browse: EC2 → Auto Scaling
   - Metric: `CPUUtilization` (Average)
   - Period: 5 minutes
4. **Conditions:**
   - Threshold: Static
   - Greater than: `80`
   - for: 2 out of 3 data points
5. **Notification:**
   - Pode deixar sem notificação para competição
6. **Name:**
   - Name: `capirentals-high-cpu`
   - Description: `Alarm when CPU > 80%`

**Alarme 2: Low Healthy Hosts**

1. Repeat process for ALB metric
2. Metric: `HealthyHostCount`
3. Condition: Less than `1`
4. Name: `capirentals-no-healthy-hosts`

---

### PASSO 10: CloudFront (Opcional) | CloudFront (Optional)

> 📝 **NOTA**: CloudFront é opcional para este desafio, já que `/calc` não se beneficia de cache.

#### 10.1 Criar Distribuição

1. Digite **"CloudFront"** na busca
2. Clique em **CloudFront**
3. Clique em **"Create distribution"**

#### 10.2 Configurar Origin

| Campo | Valor |
|-------|-------|
| Origin Domain Name | DNS do seu ALB (sem http://) |
| Protocol | HTTP only (ALB está em HTTP) |
| Port | 80 |

#### 10.3 Configurar Cache Behaviors

**Default Cache Behavior:**

| Campo | Valor |
|-------|-------|
| Viewer Protocol Policy | Redirect HTTP to HTTPS |
| Allowed HTTP Methods | GET, HEAD, OPTIONS |
| Cache Policy | CachingDisabled (para `/calc`) |

**Custom Cache Behavior para `/health`:**

| Campo | Valor |
|-------|-------|
| Path Pattern | `/health` |
| Cache Policy | CachingOptimized |

> 💡 **POR QUE DESABILITAR CACHE?** O endpoint `/calc` gera hashes únicos para cada input. Cache resultaria em respostas incorretas.

#### 10.4 Criar

Clique em **"Create distribution"**

#### 10.5 Testar via CloudFront

Após deploy (pode demorar 10-15 minutos):

```bash
export CF_URL=https://XXXXXXXXXXX.cloudfront.net
curl $CF_URL/health
```

---

## 5. Otimização de Custos | Cost Optimization

### Estratégias para 50 Créditos | Strategies for 50 Credits

#### 5.1 Escolha de Instance Types

| Instance | Custo/hora | Custo/dia | Recomendação |
|----------|------------|-----------|--------------|
| t2.micro | $0.0116 | $0.28 | Econômico |
| t3.micro | $0.0104 | $0.25 | Mais econômico, melhor performance |
| t3.small | $0.0208 | $0.50 | Só se necessário |

**Cálculo para competição (assumindo 4 horas):**

| Recurso | Quantidade | Custo/hora | Custo Total (4h) |
|---------|------------|------------|------------------|
| EC2 (t3.micro) | 2 | $0.0104 | $0.08 |
| ALB | 1 | $0.0225 | $0.09 |
| NAT Gateway | 0 | - | $0 (não usamos) |
| DynamoDB (On-demand) | 1 | ~$0.01 | $0.04 |
| Data Transfer | ~1GB | $0.09 | $0.09 |
| **TOTAL** | | | **~$0.30** |

**50 créditos = $50 de serviços AWS**

Você pode rodar por aproximadamente **166 horas** com os recursos acima! ⬅️ MUITO mais que suficiente.

#### 5.2 Dicas de Economia

1. **Desligue quando não usar:** Pare as instâncias quando não estiver testando
2. **Minimum capacity = 1:** Não precisa de 2 instâncias idle
3. **Evite NAT Gateway:** Use subnets públicas (economiza ~$32/mês)
4. **Use t3.micro:** Melhor custo-benefício
5. **CloudFront:** Opcional, economize se não necessário

#### 5.3 Monitorar Custos

1. No Console, digite **"Billing"**
2. Clique em **"Bills"**
3. Veja custos por serviço

---

## 6. Troubleshooting

### Problemas Comuns e Soluções | Common Issues and Solutions

#### 6.1 Instância não inicia a aplicação

**Sintomas:**
- Health check falha
- Instância marcada como "unhealthy"

**Diagnóstico:**
```bash
# SSH na instância
ssh -i ~/capirentals-key.pem ec2-user@INSTANCE_IP

# Verificar logs do serviço
sudo journalctl -u capirentals -f

# Verificar se o serviço está rodando
sudo systemctl status capirentals

# Verificar logs do sistema
tail -f /var/log/capirentals.log

# Testar localmente
curl localhost:80/health
```

**Soluções:**
1. Verificar se variáveis de ambiente estão corretas
2. Verificar se o binário tem permissão de execução
3. Verificar conectividade com DynamoDB

#### 6.2 Erro de conexão com DynamoDB

**Sintomas:**
- `/calc` retorna 500 Internal Server Error
- Logs mostram "unable to connect to DynamoDB"

**Diagnóstico:**
```bash
# Verificar se IAM role está anexada
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Testar conexão AWS CLI
aws dynamodb list-tables --region us-east-1
```

**Soluções:**
1. Verificar se IAM instance profile tem permissões DynamoDB
2. Verificar se a tabela existe e está ativa
3. Verificar se a região está correta (us-east-1)

#### 6.3 Health Check falha no ALB

**Sintomas:**
- Target marcado como "unhealthy"
- ALB não encaminha tráfego

**Verificar:**
1. Security Group permite tráfego na porta 80
2. Aplicação está rodando na porta correta
3. Health check path está correto (`/health`)

#### 6.4 Auto Scaling não funciona

**Verificar:**
1. Scaling policies configuradas corretamente
2. CloudWatch metrics estão sendo coletadas
3. Health check type está como "ELB"

#### 6.5 Não consigo acessar via browser

**Possíveis causas:**
1. ALB DNS name incorreto
2. Security Group bloqueando HTTP
3. Instâncias não estão healthy

**Verificar:**
```bash
# Verificar se Security Group permite HTTP
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# Verificar se targets estão healthy
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# Testar conectividade
curl -v http://SEU-ALB-DNS-NAME/health
```

---

## 7. Conceitos Avançados | Advanced Concepts

### 7.1 High Availability (HA)

**O que é?** A capacidade do sistema de continuar funcionando mesmo quando componentes falham.

**Como implementar:**
- Múltiplas Availability Zones (AZs)
- Load Balancer para distribuir tráfego
- Auto Scaling para substituir instâncias falhas

```
        ┌─────────────────────────────────────────────┐
        │              AWS Region (us-east-1)          │
        │                                              │
        │  ┌────────────────┐    ┌────────────────┐    │
        │  │      AZ-a      │    │      AZ-b      │    │
        │  │                │    │                │    │
        │  │   ┌────────┐   │    │   ┌────────┐   │    │
        │  │   │  EC2   │   │    │   │  EC2   │   │    │
        │  │   │  #1    │   │    │   │  #2    │   │    │
        │  │   └────────┘   │    │   └────────┘   │    │
        │  │                │    │                │    │
        │  └────────────────┘    └────────────────┘    │
        │                                              │
        │         ┌─────────────────────────┐           │
        │         │    Load Balancer        │           │
        │         └─────────────────────────┘           │
        │                                              │
        └─────────────────────────────────────────────┘

        Se AZ-a cair, AZ-b continua servindo tráfego.
        If AZ-a fails, AZ-b continues serving traffic.
```

### 7.2 Scalability (Escalabilidade)

**O que é?** A capacidade do sistema de lidar com aumento de carga.

**Tipos:**

1. **Vertical Scaling (Scale Up):** Aumentar recursos de uma instância
   - Ex: t3.micro → t3.small
   - Mais simples, mas tem limite

2. **Horizontal Scaling (Scale Out):** Adicionar mais instâncias
   - Ex: 1 instância → 3 instâncias
   - Mais complexo, mas praticamente ilimitado

**Este desafio usa Horizontal Scaling via Auto Scaling Groups.**

### 7.3 Fault Tolerance (Tolerância a Falhas)

**O que é?** A capacidade do sistema de continuar operando mesmo com falhas de componentes.

**Diferença de HA:**
- HA: sistema continua funcionando durante falha
- Fault Tolerance: sistema desenha para evitar falhas

**Como implementar:**
- Health checks automáticos
- Auto Scaling para substituir instâncias
- Multi-AZ deployment
- Graceful degradation

### 7.4 Architecture Decisions

**Por que essa arquitetura? | Why this architecture?**

| Decisão | Alternativa | Por que esta escolha? |
|----------|-------------|----------------------|
| EC2 + ASG | ECS/Fargate | Mais econômico para este caso |
| DynamoDB | RDS | Escala automática, sem manutenção |
| Public Subnets | Private + NAT | Economia significativa |
| ALB | NLB | Health checks HTTP, mais features |
| HTTP only | HTTPS | Simplicidade (adicionar HTTPS é simples) |

---

## 8. Checklist Final | Final Checklist

### Antes de Começar | Before Starting

- [ ] Lab iniciado no AWS Learner Lab
- [ ] Créditos disponíveis (50+)
- [ ] Tempo suficiente (mínimo 2 horas)

### Durante a Implementação | During Implementation

- [ ] DynamoDB table criada e ativa
- [ ] VPC configurada com 2+ subnets
- [ ] Security Groups permitem HTTP
- [ ] IAM role com permissões DynamoDB e CloudWatch
- [ ] Launch Template com User Data correto
- [ ] Load Balancer criado e functional
- [ ] Target Group com health check `/health`
- [ ] Auto Scaling Group configurado
- [ ] CloudWatch alarmes criados

### Verificação Final | Final Verification

- [ ] Acessar ALB DNS name no browser
- [ ] `/health` retorna "Healthy!"
- [ ] `/calc?input=test` retorna JSON com hash
- [ ] CloudWatch mostra métricas
- [ ] Alarmes funcionando
- [ ] Auto Scaling policy configurada

---

## 9. Comandos Úteis | Useful Commands

### AWS CLI Commands

```bash
# Verificar instâncias
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'

# Verificar health targets
aws elbv2 describe-target-health --target-group-arn TG_ARN

# Verificar Auto Scaling activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name capirentals-asg

# Verificar DynamoDB table
aws dynamodb describe-table --table-name CapiRentalsHash

# Testar aplicação
curl http://ALB-DNS-NAME/health
curl "http://ALB-DNS-NAME/calc?input=hello"
```

### Debugging Commands

```bash
# Conectar na instância
ssh -i ~/capirentals-key.pem ec2-user@INSTANCE_IP

# Verificar serviço
sudo systemctl status capirentals
sudo journalctl -u capirentals -f

# Verificar logs
tail -f /var/log/capirentals.log

# Testar local
curl localhost:80/health
```

---

## 10. Recursos Adicionais | Additional Resources

### AWS Documentation

- [EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)
- [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

### WorldSkills Tips

1. **Practice timing:** Saiba quanto tempo cada passo demora
2. **Have backups:** Tenha scripts prontos para recriar recursos
3. **Document everything:** Anote IDs, ARNs, DNS names
4. **Test frequently:** Teste cada componente antes de avançar
5. **Monitor costs:** Verifique Billing regularmente

---

## 11. Resumo Visual | Visual Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ARQUITETURA FINAL / FINAL ARCHITECTURE           │
└─────────────────────────────────────────────────────────────────────┘

                           INTERNET
                              │
                              ▼
                    ┌─────────────────┐
                    │   CloudFront    │ (Opcional)
                    │   CDN Cache     │
                    └────────┬────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   ALB           │ DNS: capirentals-alb-xxx.elb.amazonaws.com
                    │ Load Balancer   │
                    │ Porta: 80       │
                    │ Health: /health │
                    └────────┬────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │   EC2    │   │   EC2    │   │   EC2    │
        │ t3.micro │   │ t3.micro │   │ t3.micro │
        │ App Go   │   │ App Go   │   │ App Go   │
        │ Porta 80 │   │ Porta 80 │   │ Porta 80 │
        └────┬─────┘   └────┬─────┘   └────┬─────┘
             │              │              │
             └──────────────┼──────────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │    DynamoDB     │
                   │ Table: CapiRentalsHash
                   │ Key: id         │
                   └─────────────────┘

                    ┌─────────────────┐
                    │   CloudWatch    │ ← Monitoramento
                    │   Alarms        │
                    │   Dashboard     │
                    └─────────────────┘

        ┌─────────────────────────────────────────────┐
        │         Auto Scaling Group                  │
        │   Min: 1  Desired: 2  Max: 3               │
        │   Policy: CPU > 70% → Scale Out            │
        └─────────────────────────────────────────────┘
```

---

## 12. Conclusão | Conclusion

Você agora tem uma aplicação Go:
- ✅ Alta disponibilidade (multi-AZ)
- ✅ Escalável (Auto Scaling)
- ✅ Monitorada (CloudWatch)
- ✅ Balanceada (ALB)
- ✅ Persistente (DynamoDB)

**Custo estimado:** ~$0.30 por 4 horas de competição

**Tempo de implementação:** 1-2 horas

Good luck in the competition! 🏆

---

**Created for:** WorldSkills Brasil Cloud Computing Competition 2024  
**Author:** Kiro AI Assistant  
**Last Updated:** 2024
