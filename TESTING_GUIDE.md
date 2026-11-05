# Guia de Testes - Capi's Rentals Application
# Testing Guide - Capi's Rentals Application

Este guia mostra como testar a aplicação Capi's Rentals em Windows (PowerShell) e Linux/macOS (Bash).

---

## 📋 Pré-requisitos | Prerequisites

### Windows (PowerShell)
- PowerShell 5.1 ou superior
- Conexão com a internet

### Linux/macOS (Bash)
- Terminal Bash
- `curl` instalado (geralmente já vem por padrão)
- Para testes de carga: `ab` (Apache Benchmark) - opcional

---

## 🔧 Configuração Inicial | Initial Setup

### Windows (PowerShell)

```powershell
# Definir a URL base (substitua pelo seu DNS do ALB)
$env:BASE_URL="http://capirentals-alb-1380487890.us-east-1.elb.amazonaws.com"
```

### Linux/macOS (Bash)

```bash
# Definir a URL base (substitua pelo seu DNS do ALB)
export BASE_URL=http://capirentals-alb-1380487890.us-east-1.elb.amazonaws.com
```

---

## 🧪 Testes Básicos | Basic Tests

### 1. Testar Health Endpoint

#### Windows (PowerShell)

```powershell
# Opção 1: Usando Invoke-WebRequest
Invoke-WebRequest -Uri "$env:BASE_URL/health"

# Opção 2: Usando curl (alias)
curl "$env:BASE_URL/health"

# Opção 3: Usando curl.exe (curl real do Windows)
curl.exe "$env:BASE_URL/health"
```

#### Linux/macOS (Bash)

```bash
# Usando curl
curl $BASE_URL/health

# Verbose (detalhado)
curl -v $BASE_URL/health
```

**Resposta Esperada:** `Healthy!`

---

### 2. Testar Calc Endpoint

#### Windows (PowerShell)

```powershell
# Teste básico
curl "$env:BASE_URL/calc?input=test"

# Ver resposta formatada
$response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=test"
$response.Content

# Converter JSON para objeto
$content = $response.Content | ConvertFrom-Json
Write-Host "Hash: $($content.base64_hash)"
```

#### Linux/macOS (Bash)

```bash
# Teste básico
curl "$BASE_URL/calc?input=test"

# Ver resposta formatada (pretty print)
curl "$BASE_URL/calc?input=test" | json_pp

# Ou usando jq (se instalado)
curl "$BASE_URL/calc?input=test" | jq
```

**Resposta Esperada:**
```json
{"base64_hash":"dGVzdA=="}
```

---

### 3. Testar com Inputs Diferentes

#### Windows (PowerShell)

```powershell
# Lista de inputs para testar
$inputs = @("worldskills", "brasil", "cloud", "computing", "2024")

foreach ($input in $inputs) {
    $response = Invoke-WebRequest -Uri "$env:BASE_URL/calc?input=$input"
    $content = $response.Content | ConvertFrom-Json
    Write-Host "Input: $input -> Hash: $($content.base64_hash)"
}
```

#### Linux/macOS (Bash)

```bash
# Lista de inputs para testar
for input in worldskills brasil cloud computing 2024; do
    echo "Input: $input -> Hash: $(curl -s "$BASE_URL/calc?input=$input" | grep -o '"base64_hash":"[^"]*"')"
done
```

---

## 📊 Testes de Carga | Load Testing

### Usando Scripts de Teste

#### Windows (PowerShell)

```powershell
# Executar script de testes completo
.\test_requests.ps1

# Com parâmetros personalizados
.\test_requests.ps1 -BASE_URL "http://seu-alb-dns" -NUM_REQUESTS 20
```

#### Linux/macOS (Bash)

```bash
# Executar script de testes
bash test_requests.sh

# Se tiver o Apache Benchmark (ab) instalado:
# Ubuntu/Debian: sudo apt-get install apache2-utils
# macOS: brew install httpd
```

---

## 🔍 Verificação de Status | Status Verification

### Verificar Status das Instâncias

#### Windows (PowerShell) - Via AWS CLI

```powershell
# Listar instâncias EC2
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'

# Verificar health dos targets
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/capirentals-targets/ID
```

#### Linux/macOS (Bash) - Via AWS CLI

```bash
# Listar instâncias EC2
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}'

# Verificar health dos targets
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT_ID:targetgroup/capirentals-targets/ID
```

---

## 🐛 Troubleshooting | Solução de Problemas

### Problema: Connection Timeout

#### Windows (PowerShell)

```powershell
# Verificar conectividade
Test-NetConnection -ComputerName capirentals-alb-1380487890.us-east-1.elb.amazonaws.com -Port 80

# Verificar DNS
Resolve-DnsName capirentals-alb-1380487890.us-east-1.elb.amazonaws.com
```

#### Linux/macOS (Bash)

```bash
# Verificar conectividade
ping capirentals-alb-1380487890.us-east-1.elb.amazonaws.com

# Verificar porta
nc -zv capirentals-alb-1380487890.us-east-1.elb.amazonaws.com 80

# Verificar DNS
nslookup capirentals-alb-1380487890.us-east-1.elb.amazonaws.com
```

---

### Problema: Status 5xx (Internal Server Error)

#### Verificar logs via SSH/Session Manager

**Windows (PowerShell) - Se tiver SSH:**

```powershell
# Conectar via SSH (se tiver a key pair)
ssh -i .\capirentals-key.pem ec2-user@IP_DA_INSTANCIA

# Dentro da instância:
sudo journalctl -u capirentals -f
```

**Linux/macOS (Bash):**

```bash
# Conectar via SSH
ssh -i ./capirentals-key.pem ec2-user@IP_DA_INSTANCIA

# Dentro da instância:
sudo journalctl -u capirentals -f
```

---

## 🌐 Teste pelo Navegador | Browser Testing

Você também pode testar diretamente no navegador:

1. **Health Check:**
   ```
   http://capirentals-alb-1380487890.us-east-1.elb.amazonaws.com/health
   ```

2. **Calc Endpoint:**
   ```
   http://capirentals-alb-1380487890.us-east-1.elb.amazonaws.com/calc?input=teste
   ```

**Dica:** Troque `teste` por qualquer palavra que quiser testar!

---

## ✅ Checklist de Verificação | Verification Checklist

- [ ] Health endpoint retorna "Healthy!"
- [ ] Calc endpoint retorna JSON com hash base64
- [ ] Instâncias estão marcadas como "healthy" no Target Group
- [ ] Load Balancer está distribuindo tráfego
- [ ] DynamoDB está salvando os hashes (verificar no console)
- [ ] CloudWatch está coletando métricas (se configurado)

---

## 📝 Comandos Úteis | Useful Commands

### PowerShell (Windows)

```powershell
# Verificar variável de ambiente
$env:BASE_URL

# Fazer múltiplas requisições
1..10 | ForEach-Object { curl "$env:BASE_URL/health" }

# Ver código de status HTTP
$response = Invoke-WebRequest -Uri "$env:BASE_URL/health"
$response.StatusCode

# Ver headers da resposta
$response.Headers
```

### Bash (Linux/macOS)

```bash
# Verificar variável de ambiente
echo $BASE_URL

# Fazer múltiplas requisições
for i in {1..10}; do curl $BASE_URL/health; done

# Ver código de status HTTP
curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health

# Ver headers da resposta
curl -I $BASE_URL/health
```

---

## 🎯 Testes Avançados | Advanced Testing

### Teste de Performance (requer Apache Benchmark)

#### Linux/macOS

```bash
# Instalar Apache Benchmark
# Ubuntu/Debian:
sudo apt-get install apache2-utils

# macOS:
brew install httpd

# Executar teste de carga
ab -n 100 -c 10 $BASE_URL/health
```

#### Windows

```powershell
# Não há equivalente nativo simples
# Use o script test_requests.ps1 com NUM_REQUESTS alto:
.\test_requests.ps1 -NUM_REQUESTS 100
```

---

## 📞 Suporte | Support

Se encontrar problemas:

1. Verifique se o ALB DNS está correto
2. Verifique se as instâncias estão healthy no Target Group
3. Verifique os Security Groups
4. Verifique os logs das instâncias via Session Manager ou SSH

---

**Created for:** WorldSkills Brasil Cloud Computing Competition 2024
**Author:** Kiro AI Assistant
**Last Updated:** 2024
