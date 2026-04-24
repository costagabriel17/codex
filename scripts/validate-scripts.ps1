$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$report = New-ReportContext -Action "validate-scripts"
$summary = @{
    action = "validate-scripts"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        scriptsRoot = $PSScriptRoot
    }
    results = @{
        checkedFiles = @()
    }
    validation = @()
    errors = @()
}

try {
    Write-Step "Validando scripts PowerShell"
    $scriptFiles = Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File -Filter *.ps1 | Sort-Object FullName

    foreach ($scriptFile in $scriptFiles) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors) | Out-Null

        if ($errors.Count -gt 0) {
            foreach ($parseError in $errors) {
                $summary.errors += @{
                    file = $scriptFile.FullName
                    message = $parseError.Message
                }
            }

            throw "Falha de sintaxe encontrada em $($scriptFile.FullName)"
        }

        $summary.results.checkedFiles += $scriptFile.FullName
        Write-Host "OK: $($scriptFile.FullName)"
    }

    $summary.status = "success"
    $summary.validation += @{
        type = "powershell-parser"
        status = "passed"
        details = "Todos os scripts .ps1 foram validados sem erro de sintaxe."
    }

    Write-Host ""
    Write-Host "Validacao concluida com sucesso." -ForegroundColor Green
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
