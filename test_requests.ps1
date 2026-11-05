# Test Script for Capi's Rentals Application
# Script de Teste para Aplicação Capi's Rentals
# PowerShell Version

param(
    [string]$BASE_URL = "http://capirentals-alb-1380487890.us-east-1.elb.amazonaws.com",
    [int]$NUM_REQUESTS = 10
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Capi's Rentals Application" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test health endpoint
Write-Host "[1] Testing /health endpoint..." -ForegroundColor Green
Write-Host "URL: $BASE_URL/health" -ForegroundColor Gray
Write-Host ""

$healthSuccess = 0
$healthFail = 0

for ($i = 1; $i -le $NUM_REQUESTS; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/health" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "  Request $i : Status $($response.StatusCode) - OK" -ForegroundColor Green
            $healthSuccess++
        }
    }
    catch {
        Write-Host "  Request $i : FAILED - $($_.Exception.Message)" -ForegroundColor Red
        $healthFail++
    }
}

Write-Host ""
Write-Host "Health Endpoint Results:" -ForegroundColor Yellow
Write-Host "  Success: $healthSuccess / $NUM_REQUESTS" -ForegroundColor Green
Write-Host "  Failed:  $healthFail / $NUM_REQUESTS" -ForegroundColor $(if ($healthFail -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Test calc endpoint
Write-Host "[2] Testing /calc endpoint..." -ForegroundColor Green
Write-Host "URL: $BASE_URL/calc?input=test" -ForegroundColor Gray
Write-Host ""

$calcSuccess = 0
$calcFail = 0
$hashes = @()

for ($i = 1; $i -le $NUM_REQUESTS; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/calc?input=test$i" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "  Request $i : Status $($response.StatusCode) - OK" -ForegroundColor Green
            $content = $response.Content | ConvertFrom-Json
            $hashes += $content.base64_hash
            $calcSuccess++
        }
    }
    catch {
        Write-Host "  Request $i : FAILED - $($_.Exception.Message)" -ForegroundColor Red
        $calcFail++
    }
}

Write-Host ""
Write-Host "Calc Endpoint Results:" -ForegroundColor Yellow
Write-Host "  Success: $calcSuccess / $NUM_REQUESTS" -ForegroundColor Green
Write-Host "  Failed:  $calcFail / $NUM_REQUESTS" -ForegroundColor $(if ($calcFail -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Show sample hashes
if ($hashes.Count -gt 0) {
    Write-Host "Sample Hashes Generated:" -ForegroundColor Yellow
    for ($i = 0; $i -lt [Math]::Min(3, $hashes.Count); $i++) {
        Write-Host "  Hash $($i + 1): $($hashes[$i])" -ForegroundColor Gray
    }
    Write-Host ""
}

# Test with custom inputs
Write-Host "[3] Testing with custom inputs..." -ForegroundColor Green
Write-Host ""

$testInputs = @("worldskills", "brasil", "cloud", "computing", "2024")

foreach ($input in $testInputs) {
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/calc?input=$input" -UseBasicParsing -TimeoutSec 10
        $content = $response.Content | ConvertFrom-Json
        Write-Host "  Input: '$input' -> Hash: $($content.base64_hash)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  Input: '$input' -> FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Health: $healthSuccess/$NUM_REQUESTS successful" -ForegroundColor Green
Write-Host "  Calc:   $calcSuccess/$NUM_REQUESTS successful" -ForegroundColor Green
Write-Host ""
