$ErrorActionPreference = "Stop"

. $PSScriptRoot\lib\reporting.ps1

Write-Host ""
Write-Host "==> Preparando pasta de trabalho" -ForegroundColor Cyan

$repoRoot = Get-ProjectRoot
$gitDir = Join-Path $repoRoot ".git"

if (Test-Path -LiteralPath $gitDir) {
    Push-Location $repoRoot
    try {
        $gitExe = Get-Command git -ErrorAction SilentlyContinue
        if ($gitExe) {
            & $gitExe.Source pull --ff-only origin main
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "Pronto. O projeto foi atualizado com git pull." -ForegroundColor Green
                return
            }
        }
    }
    finally {
        Pop-Location
    }
}

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "sync-from-github.ps1")

Write-Host ""
Write-Host "Pronto. A pasta local foi preparada para voce comecar o trabalho." -ForegroundColor Green
