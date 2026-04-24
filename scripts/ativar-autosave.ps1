param(
    [int]$EveryMinutes = 15,
    [string]$TaskName = "CodexShopifyAutoSave"
)

$ErrorActionPreference = "Stop"
$env:PROJECT_REPORTS_SUBDIR = "runtime"
. (Join-Path $PSScriptRoot "lib\reporting.ps1")

if ($EveryMinutes -lt 5) {
    throw "O intervalo minimo recomendado para autosave e 5 minutos."
}

$report = New-ReportContext -Action "ativar-autosave"
$summary = @{
    action = "ativar-autosave"
    status = "running"
    startedAt = $report.StartedAt
    inputs = @{
        everyMinutes = $EveryMinutes
        taskName = $TaskName
    }
    results = @{
        taskRegistered = $false
    }
    validation = @()
    errors = @()
}

try {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "configurar-git-local.ps1")

    $scriptPath = Join-Path $PSScriptRoot "autosave-to-github.ps1"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $EveryMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

    $summary.status = "success"
    $summary.results.taskRegistered = $true
    $summary.validation += @{
        type = "scheduled-task"
        status = "passed"
        details = "Tarefa de autosave registrada com sucesso."
    }

    Write-Host ""
    Write-Host "Autosave ativado com sucesso." -ForegroundColor Green
    Write-Host "Intervalo: $EveryMinutes minutos" -ForegroundColor Green
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
