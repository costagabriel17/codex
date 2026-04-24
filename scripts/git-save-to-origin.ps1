param(
    [string]$Message = "Atualiza projeto Shopify"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

function Write-Step {
    param([string]$MessageText)
    Write-Host ""
    Write-Host "==> $MessageText" -ForegroundColor Cyan
}

$report = New-ReportContext -Action "git-save-to-origin"
$summary = @{
    action = "git-save-to-origin"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        message = $Message
    }
    results = @{
        changedFiles = @()
        commitSha = $null
        branch = $null
    }
    validation = @()
    errors = @()
}

$repoRoot = Get-ProjectRoot
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) {
    throw "Git nao encontrado nesta maquina."
}

Push-Location $repoRoot

try {
    $currentBranch = (& $gitExe.Source branch --show-current).Trim()
    $summary.results.branch = $currentBranch

    if ([string]::IsNullOrWhiteSpace((& $gitExe.Source config user.name))) {
        powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "configurar-git-local.ps1")
    }

    $statusLines = & $gitExe.Source status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao ler o estado do Git."
    }

    if (-not $statusLines) {
        $summary.status = "success"
        $summary.validation += @{
            type = "git-status"
            status = "passed"
            details = "Nenhuma mudanca local para salvar."
        }

        Write-Host "Nenhuma mudanca local para salvar." -ForegroundColor Green
        Write-Host "Report: $($report.SummaryPath)"
        return
    }

    $summary.results.changedFiles = @($statusLines | ForEach-Object { $_.Substring(3) })

    Write-Step "Criando commit local"
    & $gitExe.Source add -A

    $stagedFiles = & $gitExe.Source diff --cached --name-only
    if (-not $stagedFiles) {
        $summary.status = "success"
        $summary.validation += @{
            type = "git-stage"
            status = "passed"
            details = "Nao houve arquivo elegivel para commit."
        }

        Write-Host "Nao houve arquivo elegivel para commit." -ForegroundColor Green
        Write-Host "Report: $($report.SummaryPath)"
        return
    }

    & $gitExe.Source commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao criar commit local."
    }

    $summary.results.commitSha = (& $gitExe.Source rev-parse HEAD).Trim()

    Write-Step "Sincronizando com origin/main"
    & $gitExe.Source pull --rebase origin main
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao rebasear com origin/main."
    }

    Write-Step "Enviando commit para o GitHub"
    & $gitExe.Source push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao enviar commit para o GitHub."
    }

    $summary.status = "success"
    $summary.validation += @{
        type = "git-push"
        status = "passed"
        details = "Commit criado e enviado com sucesso para origin/main."
    }

    Write-Host ""
    Write-Host "Commit salvo no GitHub com sucesso." -ForegroundColor Green
    Write-Host "Report: $($report.SummaryPath)"
}
catch {
    $summary.status = "failed"
    $summary.errors += @{
        message = $_.Exception.Message
    }
    throw
}
finally {
    Pop-Location
    Write-ReportSummary -Summary $summary -SummaryPath $report.SummaryPath
}
