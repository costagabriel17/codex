$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==> Sincronizando com o GitHub" -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "sync-from-github.ps1")

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao sincronizar com o GitHub."
}

Write-Host ""
Write-Host "Pronto. A pasta local foi preparada para voce comecar o trabalho." -ForegroundColor Green
