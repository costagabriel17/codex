param(
    [string]$MessagePrefix = "Autosave"
)

$ErrorActionPreference = "Stop"
$env:PROJECT_REPORTS_SUBDIR = "autosave"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

function Write-Step {
    param([string]$MessageText)
    Write-Host ""
    Write-Host "==> $MessageText" -ForegroundColor Cyan
}

$report = New-ReportContext -Action "autosave-to-github"
$summary = @{
    action = "autosave-to-github"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        messagePrefix = $MessagePrefix
    }
    results = @{
        mode = $null
        scheduledCommitMessage = $null
    }
    validation = @()
    errors = @()
}

$repoRoot = Get-ProjectRoot
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) {
    throw "Git nao encontrado nesta maquina."
}

$mutex = [System.Threading.Mutex]::new($false, "Local\CodexShopifyAutoSave")
$lockAcquired = $false

Push-Location $repoRoot

try {
    $lockAcquired = $mutex.WaitOne(0, $false)
    if (-not $lockAcquired) {
        $summary.status = "success"
        $summary.results.mode = "noop-already-running"
        $summary.validation += @{
            type = "autosave-lock"
            status = "passed"
            details = "Outra execucao de autosave ja estava em andamento."
        }

        Write-Host "Outra execucao de autosave ja esta em andamento." -ForegroundColor Yellow
        Write-Host "Report: $($report.SummaryPath)"
        return
    }

    if ((Test-Path ".git\MERGE_HEAD") -or (Test-Path ".git\rebase-merge") -or (Test-Path ".git\rebase-apply")) {
        throw "O repositorio esta em estado de merge/rebase. Resolva isso antes de usar o autosave."
    }

    $statusLines = & $gitExe.Source status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao ler o estado do Git."
    }

    if (-not $statusLines) {
        $summary.status = "success"
        $summary.results.mode = "noop-clean"
        $summary.validation += @{
            type = "git-status"
            status = "passed"
            details = "Nenhuma mudanca detectada para autosave."
        }

        Write-Host "Nenhuma mudanca detectada para autosave." -ForegroundColor Green
        Write-Host "Report: $($report.SummaryPath)"
        return
    }

    $commitMessage = "$MessagePrefix $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $summary.results.mode = "save-and-push"
    $summary.results.scheduledCommitMessage = $commitMessage

    Write-Step "Validando scripts PowerShell"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate-scripts.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "Falha na validacao de scripts durante o autosave."
    }

    Write-Step "Validando padrao estrutural do projeto"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "validate-project-standards.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "Falha na validacao estrutural durante o autosave."
    }

    Write-Step "Salvando automaticamente no GitHub"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "git-save-to-origin.ps1") -Message $commitMessage
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar o autosave no GitHub."
    }

    $summary.status = "success"
    $summary.validation += @{
        type = "autosave"
        status = "passed"
        details = "Autosave validou e publicou as mudancas com sucesso."
    }

    Write-Host ""
    Write-Host "Autosave concluido com sucesso." -ForegroundColor Green
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
    if ($lockAcquired) {
        $mutex.ReleaseMutex() | Out-Null
    }

    $mutex.Dispose()
    Pop-Location
    Write-ReportSummary -Summary $summary -SummaryPath $report.SummaryPath
}
