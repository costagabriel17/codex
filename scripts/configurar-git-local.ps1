$ErrorActionPreference = "Stop"
$env:PROJECT_REPORTS_SUBDIR = "runtime"

Write-Host ""
Write-Host "==> Configurando identidade local do Git" -ForegroundColor Cyan

$ghExe = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghExe) {
    throw "GitHub CLI nao encontrado nesta maquina."
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
Push-Location $repoRoot

try {
    $login = (& $ghExe.Source api user --jq .login).Trim()
    $id = (& $ghExe.Source api user --jq .id).Trim()

    if ([string]::IsNullOrWhiteSpace($login) -or [string]::IsNullOrWhiteSpace($id)) {
        throw "Nao foi possivel ler a identidade da conta GitHub."
    }

    $email = "$id+$login@users.noreply.github.com"

    git config user.name $login
    git config user.email $email

    Write-Host "Git local configurado com sucesso para $login." -ForegroundColor Green
}
finally {
    Pop-Location
}
