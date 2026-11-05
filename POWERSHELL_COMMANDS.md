# Comandos PowerShell para AWS
# PowerShell Commands for AWS

Este documento complementa o AWS_DEPLOYMENT_GUIDE.md com comandos específicos para Windows PowerShell.

---

## 🔧 Configuração Inicial

### Variáveis de Ambiente

#### Linux/macOS (Bash)
```bash
export BASE_URL=http://capirentals-alb-123456789.us-east-1.elb.amazonaws.com
export AWS_REGION=us-east-1
```

#### Windows (PowerShell)
```powershell
$env:BASE_URL="http://capirentals-alb-123456789.us-east-1.elb.amazonaws.com"
$env:AWS_REGION="us-east-1"
```

---

## 🧪 Testes da Aplicação

### 1. Testar Health Endpoint

#### Linux/macOS (Bash)
```bash
curl $BASE_URL/health
```

#### Windows (PowerShell)
```powershell
# Opção 1: Invoke-WebRequest
Invoke-WebRequest -Uri "$env:BASE_URL/health"

# Opção 2: curl (alias)
curl "$env:BASE_URL/health"

# Opção 3: curl.exe (curl real)
curl.exe "$env:BASE_URL/health"
```

---

### 2. Testar Calc Endpoint

#### Linux/macOS (Bash)
```bash
curl "$BASE_URL/calc?input=test"
```

#### Windows (PowerShell)
```powershell
# Opção 1: Simples
curl "$env:BASE_URL/calc?input=test"

# Opção 2: Ver JSON formatado
$response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=test"
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

---

### 3. Múltiplas Requisições

#### Linux/macOS (Bash)
```bash
# 10 requisições para /health
for i in {1..10}; do curl $BASE_URL/health; done

# 10 requisições com numeração
for i in {1..10}; do echo "Request $i"; curl $BASE_URL/health; done
```

#### Windows (PowerShell)
```powershell
# 10 requisições para /health
1..10 | ForEach-Object { 
    $response = Invoke-WebRequest -Uri "$env:BASE_URL/health"
    Write-Host "Request $_ : Status $($response.StatusCode)"
}

# Ou com script estruturado
for ($i = 1; $i -le 10; $i++) {
    $response = Invoke-WebRequest -Uri "$env:BASE_URL/health"
    Write-Host "Request $i : Status $($response.StatusCode)"
}
```

---

## 🔍 Verificação de Recursos AWS

### 1. Instâncias EC2

#### Linux/macOS (Bash)
```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'
```

#### Windows (PowerShell)
```powershell
# Usando AWS CLI
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'

# Usando AWS PowerShell Tools (se instalado)
Get-EC2Instance | Select-Object -ExpandProperty Instances | Select-Object InstanceId, State, PublicIpAddress
```

---

### 2. Target Groups Health

#### Linux/macOS (Bash)
```bash
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/capirentals-targets/ID
```

#### Windows (PowerShell)
```powershell
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/capirentals-targets/ID
```

---

### 3. DynamoDB

#### Linux/macOS (Bash)
```bash
# Listar tabelas
aws dynamodb list-tables --region us-east-1

# Descrever tabela
aws dynamodb describe-table --table-name CapiRentalsHash --region us-east-1
```

#### Windows (PowerShell)
```powershell
# Listar tabelas
aws dynamodb list-tables --region us-east-1

# Descrever tabela
aws dynamodb describe-table --table-name CapiRentalsHash --region us-east-1

# Ler itens da tabela (PowerShell)
aws dynamodb scan --table-name CapiRentalsHash --region us-east-1
```

---

## 🐛 Troubleshooting

### 1. Teste de Conectividade

#### Linux/macOS (Bash)
```bash
# Ping
ping capirentals-alb-xxx.elb.amazonaws.com

# Testar porta
nc -zv capirentals-alb-xxx.elb.amazonaws.com 80

# Verificar DNS
nslookup capirentals-alb-xxx.elb.amazonaws.com
```

#### Windows (PowerShell)
```powershell
# Teste de conexão TCP
Test-NetConnection -ComputerName capirentals-alb-xxx.elb.amazonaws.com -Port 80

# Verificar DNS
Resolve-DnsName capirentals-alb-xxx.elb.amazonaws.com

# Ping
Test-Connection capirentals-alb-xxx.elb.amazonaws.com
```

---

### 2. Debugging na Instância (via SSH)

#### Linux/macOS (Bash)
```bash
# Conectar via SSH
ssh -i ~/capirentals-key.pem ec2-user@INSTANCE_IP

# Dentro da instância:
sudo journalctl -u capirentals -f
sudo systemctl status capirentals
curl localhost:80/health
```

#### Windows (PowerShell)
```powershell
# Conectar via SSH (se tiver OpenSSH instalado)
ssh -i .\capirentals-key.pem ec2-user@INSTANCE_IP

# Dentro da instância (Linux):
sudo journalctl -u capirentals -f
sudo systemctl status capirentals
curl localhost:80/health
```

---

## 📊 Scripts de Teste

### Linux/macOS (Bash)

Arquivo: `test_requests.sh`
```bash
#!/bin/bash
export BASE_URL=http://capirentals-alb-xxx.elb.amazonaws.com

echo "Testing /health..."
for i in {1..10}; do
    curl $BASE_URL/health
done

echo "Testing /calc..."
for i in {1..10}; do
    curl "$BASE_URL/calc?input=test$i"
done
```

Executar:
```bash
chmod +x test_requests.sh
./test_requests.sh
```

---

### Windows (PowerShell)

Arquivo: `test_requests.ps1`
```powershell
$env:BASE_URL="http://capirentals-alb-xxx.elb.amazonaws.com"

Write-Host "Testing /health..." -ForegroundColor Green
1..10 | ForEach-Object {
    $response = Invoke-WebRequest -Uri "$env:BASE_URL/health"
    Write-Host "Request $_ : Status $($response.StatusCode)"
}

Write-Host "Testing /calc..." -ForegroundColor Green
1..10 | ForEach-Object {
    $response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=test$_"
    Write-Host "Request $_ : Status $($response.StatusCode)"
}
```

Executar:
```powershell
.\test_requests.ps1
```

---

## 🎯 Verificação Rápida

### Script de Verificação Completa

#### Linux/macOS (Bash)
```bash
#!/bin/bash
export BASE_URL=http://capirentals-alb-xxx.elb.amazonaws.com

echo "1. Testing Health..."
curl -s $BASE_URL/health && echo " ✅"

echo "2. Testing Calc..."
curl -s "$BASE_URL/calc?input=test" && echo " ✅"

echo "3. Checking Instances..."
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId'

echo "4. Checking Target Health..."
aws elbv2 describe-target-health --target-group-arn YOUR_TG_ARN --query 'TargetHealthDescriptions[].TargetHealth.State'
```

#### Windows (PowerShell)
```powershell
$env:BASE_URL="http://capirentals-alb-xxx.elb.amazonaws.com"

Write-Host "1. Testing Health..." -ForegroundColor Green
$response = Invoke-WebRequest -Uri "$env:BASE_URL/health"
Write-Host "   Status: $($response.StatusCode) ✅" -ForegroundColor Green

Write-Host "2. Testing Calc..." -ForegroundColor Green
$response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=test"
Write-Host "   Status: $($response.StatusCode) ✅" -ForegroundColor Green

Write-Host "3. Checking Instances..." -ForegroundColor Green
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId'

Write-Host "4. Checking Target Health..." -ForegroundColor Green
aws elbv2 describe-target-health --target-group-arn YOUR_TG_ARN --query 'TargetHealthDescriptions[].TargetHealth.State'
```

---

## 💡 Dicas Específicas do PowerShell

### Trabalhando com JSON

```powershell
# Fazer requisição e converter JSON
$response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=test"
$json = $response.Content | ConvertFrom-Json

# Acessar propriedade
Write-Host "Hash: $($json.base64_hash)"

# Converter para JSON formatado
$json | ConvertTo-Json
```

### Verbose Output

```powershell
# Ver todos os detalhes da resposta
$response = Invoke-WebRequest -Uri "$env:BASE_URL/health" -Verbose

# Ver headers
$response.Headers

# Ver código de status
$response.StatusCode

# Ver conteúdo
$response.Content
```

### Timeouts

```powershell
# Definir timeout (em segundos)
Invoke-WebRequest -Uri "$env:BASE_URL/health" -TimeoutSec 30
```

---

## 📝 Checklist de Comandos

### Antes de Testar

#### Linux/macOS
```bash
# Verificar se curl está instalado
which curl

# Verificar se AWS CLI está instalado
aws --version
```

#### Windows
```powershell
# Verificar se AWS CLI está instalado
aws --version

# Verificar versão do PowerShell
$PSVersionTable.PSVersion
```

---

## 🚀 Quick Start

### Linux/macOS
```bash
export BASE_URL=http://YOUR-ALB-DNS
curl $BASE_URL/health
curl "$BASE_URL/calc?input=test"
```

### Windows
```powershell
$env:BASE_URL="http://YOUR-ALB-DNS"
curl "$env:BASE_URL/health"
curl "$env:BASE_URL/calc?input=test"
```

---

**Created for:** WorldSkills Brasil Cloud Computing Competition 2024
**Author:** Kiro AI Assistant
**Last Updated:** 2024
