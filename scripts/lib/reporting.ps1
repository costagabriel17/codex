function Get-ProjectRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
}

function Get-ReportsRoot {
    $reportsRoot = Join-Path (Get-ProjectRoot) "reports"
    $reportsSubdir = $env:PROJECT_REPORTS_SUBDIR

    if (-not [string]::IsNullOrWhiteSpace($reportsSubdir)) {
        if ($reportsSubdir.Contains("..")) {
            throw "PROJECT_REPORTS_SUBDIR invalido."
        }

        $segments = $reportsSubdir -split "[\\/]+" | Where-Object { $_ }
        foreach ($segment in $segments) {
            $reportsRoot = Join-Path $reportsRoot $segment
        }
    }

    if (-not (Test-Path -LiteralPath $reportsRoot)) {
        New-Item -ItemType Directory -Path $reportsRoot | Out-Null
    }

    return $reportsRoot
}

function New-ReportContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeAction = ($Action -replace "[^a-zA-Z0-9\-]", "-").ToLowerInvariant()
    $reportDir = Join-Path (Get-ReportsRoot) "$timestamp-$safeAction"

    if (-not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir | Out-Null
    }

    return @{
        Action = $Action
        StartedAt = (Get-Date).ToString("o")
        ReportDir = $reportDir
        SummaryPath = Join-Path $reportDir "summary.json"
    }
}

function Write-ReportSummary {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Summary,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath
    )

    $Summary.finishedAt = (Get-Date).ToString("o")
    $json = $Summary | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $SummaryPath -Value $json -Encoding UTF8
}
