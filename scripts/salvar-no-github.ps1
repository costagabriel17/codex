param(
    [string]$Message = "Atualiza projeto Shopify"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==> Validando scripts PowerShell" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate-scripts.ps1")

if ($LASTEXITCODE -ne 0) {
    throw "Falha na validacao de scripts."
}

Write-Host ""
Write-Host "==> Validando padrao estrutural do projeto" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate-project-standards.ps1")

if ($LASTEXITCODE -ne 0) {
    throw "Falha na validacao estrutural."
}

Write-Host ""
Write-Host "==> Salvando no GitHub" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "git-save-to-origin.ps1") -Message $Message

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao salvar no GitHub."
}

Write-Host ""
Write-Host "Pronto. O trabalho foi validado e salvo no GitHub." -ForegroundColor Green
