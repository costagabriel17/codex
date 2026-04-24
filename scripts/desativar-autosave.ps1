param(
    [string]$TaskName = "CodexShopifyAutoSave"
)

$ErrorActionPreference = "Stop"
$env:PROJECT_REPORTS_SUBDIR = "runtime"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

$report = New-ReportContext -Action "desativar-autosave"
$summary = @{
    action = "desativar-autosave"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        taskName = $TaskName
    }
    results = @{
        taskRemoved = $false
    }
    validation = @()
    errors = @()
}

try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        $summary.results.taskRemoved = $true
    }

    $summary.status = "success"
    $summary.validation += @{
        type = "scheduled-task"
        status = "passed"
        details = "Tarefa de autosave removida ou ausente."
    }

    Write-Host ""
    Write-Host "Autosave desativado com sucesso." -ForegroundColor Green
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
    Write-ReportSummary -Summary $summary -SummaryPath $report.SummaryPath
}
