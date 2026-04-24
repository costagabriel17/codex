$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Add-CheckResult {
    param(
        [hashtable]$Summary,
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Summary.results.checks += @{
        name = $Name
        passed = $Passed
        details = $Details
    }

    if (-not $Passed) {
        $Summary.errors += @{
            check = $Name
            message = $Details
        }
    }
}

$report = New-ReportContext -Action "validate-project-standards"
$summary = @{
    action = "validate-project-standards"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        projectRoot = (Get-ProjectRoot)
    }
    results = @{
        checks = @()
    }
    validation = @()
    errors = @()
}

try {
    Write-Step "Validando estrutura obrigatoria do projeto"

    $projectRoot = Get-ProjectRoot
    $requiredPaths = @(
        "README.md",
        "package.json",
        "requirements.txt",
        ".env.example",
        "deliverables\README.md",
        "scripts\README.md",
        "scripts\configurar-git-local.ps1",
        "scripts\git-save-to-origin.ps1",
        "scripts\autosave-to-github.ps1",
        "scripts\ativar-autosave.ps1",
        "scripts\desativar-autosave.ps1",
        "scripts\validate-scripts.ps1",
        "scripts\validate-project-standards.ps1",
        "src\README.md",
        "src\node\README.md",
        "src\node\lib\reporting.mjs",
        "src\node\shopify\graphql-admin-healthcheck.mjs",
        "src\python\README.md",
        "src\playwright\README.md",
        "src\playwright\audit-storefront.mjs",
        "src\theme\README.md"
    )

    foreach ($relativePath in $requiredPaths) {
        $exists = Test-Path -LiteralPath (Join-Path $projectRoot $relativePath)
        Add-CheckResult -Summary $summary -Name "path:$relativePath" -Passed $exists -Details $(if ($exists) { "Presente." } else { "Ausente." })
    }

    Write-Step "Validando package.json"
    $packageJsonPath = Join-Path $projectRoot "package.json"
    $packageJson = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json

    Add-CheckResult -Summary $summary -Name "package:type" -Passed ($packageJson.type -eq "module") -Details "package.json deve usar type=module."
    Add-CheckResult -Summary $summary -Name "package:private" -Passed ($packageJson.private -eq $true) -Details "package.json deve ser private."

    $requiredScripts = @(
        "validate:scripts",
        "validate:standards",
        "git:save",
        "autosave:run",
        "shopify:admin:healthcheck",
        "audit:storefront"
    )

    foreach ($scriptName in $requiredScripts) {
        $hasScript = $packageJson.scripts.PSObject.Properties.Name -contains $scriptName
        Add-CheckResult -Summary $summary -Name "package:scripts:$scriptName" -Passed $hasScript -Details "Script npm obrigatorio."
    }

    Write-Step "Validando protecoes em .gitignore"
    $gitignoreContent = Get-Content -LiteralPath (Join-Path $projectRoot ".gitignore") -Raw
    $requiredIgnorePatterns = @(
        ".env",
        "tmp/",
        "node_modules/",
        ".venv/",
        "playwright-report/",
        "test-results/"
    )

    foreach ($pattern in $requiredIgnorePatterns) {
        $found = $gitignoreContent.Contains($pattern)
        Add-CheckResult -Summary $summary -Name "gitignore:$pattern" -Passed $found -Details "Padrao obrigatorio em .gitignore."
    }

    if ($summary.errors.Count -gt 0) {
        throw "A validacao estrutural encontrou falhas."
    }

    $summary.status = "success"
    $summary.validation += @{
        type = "project-standards"
        status = "passed"
        details = "Estrutura obrigatoria do projeto validada com sucesso."
    }

    Write-Host ""
    Write-Host "Validacao estrutural concluida com sucesso." -ForegroundColor Green
    Write-Host "Report: $($report.SummaryPath)"
}
catch {
    if ($summary.errors.Count -eq 0) {
        $summary.errors += @{
            message = $_.Exception.Message
        }
    }

    $summary.status = "failed"
    throw
}
finally {
    Write-ReportSummary -Summary $summary -SummaryPath $report.SummaryPath
}
