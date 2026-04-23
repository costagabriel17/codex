param(
    [string]$Owner = "costagabriel17",
    [string]$Repo = "codex",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-RepoRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
}

function Invoke-GitHubGet {
    param([string]$Url)

    $headers = @{
        "User-Agent" = "codex-sync-script"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    return Invoke-RestMethod -Method Get -Uri $Url -Headers $headers
}

function Test-LocalChanges {
    param([string]$RepoRoot)

    $gitExe = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitExe) {
        throw "Git nao encontrado nesta maquina."
    }

    Push-Location $RepoRoot
    try {
        $status = & $gitExe.Source status --porcelain
        if ($LASTEXITCODE -ne 0) {
            throw "Nao foi possivel ler o estado local do repositorio."
        }

        if ($status) {
            throw "Existem mudancas locais nesta pasta. Publique ou guarde essas mudancas antes de sincronizar."
        }
    }
    finally {
        Pop-Location
    }
}

function Get-RemoteBranchInfo {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Branch
    )

    $url = "https://api.github.com/repos/$Owner/$Repo/branches/$Branch"

    try {
        return Invoke-GitHubGet -Url $url
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
            return $null
        }

        throw
    }
}

function Remove-RepoContentSafely {
    param([string]$RepoRoot)

    $allowedRoot = [System.IO.Path]::GetFullPath($RepoRoot)
    $items = Get-ChildItem -LiteralPath $RepoRoot -Force

    foreach ($item in $items) {
        if ($item.Name -in @(".git", ".codex")) {
            continue
        }

        $itemPath = [System.IO.Path]::GetFullPath($item.FullName)
        if (-not $itemPath.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Caminho fora da pasta esperada: $itemPath"
        }

        Remove-Item -LiteralPath $item.FullName -Recurse -Force
    }
}

$repoRoot = Get-RepoRoot
$stateRoot = Join-Path $repoRoot ".codex"
$lastSyncFile = Join-Path $stateRoot "last-synced.sha"

if (-not (Test-Path -LiteralPath $stateRoot)) {
    New-Item -ItemType Directory -Path $stateRoot | Out-Null
}

Write-Step "Validando mudancas locais"
Test-LocalChanges -RepoRoot $repoRoot

Write-Step "Consultando a versao mais recente no GitHub"
$branchInfo = Get-RemoteBranchInfo -Owner $Owner -Repo $Repo -Branch $Branch

if (-not $branchInfo) {
    Write-Host "O repositorio remoto ainda nao tem arquivos publicados. Nada para baixar." -ForegroundColor Yellow
    exit 0
}

$remoteSha = $branchInfo.commit.sha

if ((Test-Path -LiteralPath $lastSyncFile) -and ((Get-Content -LiteralPath $lastSyncFile -Raw).Trim() -eq $remoteSha)) {
    Write-Host "Esta pasta ja esta sincronizada com a ultima versao do GitHub." -ForegroundColor Green
    exit 0
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-sync-" + [System.Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $tempRoot "repo.tar.gz"

New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    Write-Step "Baixando a versao mais recente"
    $archiveUrl = "https://api.github.com/repos/$Owner/$Repo/tarball/$Branch"

    $headers = @{
        "User-Agent" = "codex-sync-script"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    Invoke-WebRequest -Uri $archiveUrl -Headers $headers -OutFile $archivePath

    Write-Step "Aplicando atualizacao local"
    tar -xzf $archivePath -C $tempRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao extrair o pacote baixado do GitHub."
    }

    $extractedRoot = Get-ChildItem -LiteralPath $tempRoot -Directory | Where-Object { $_.Name -ne ".codex" } | Select-Object -First 1
    if (-not $extractedRoot) {
        throw "Nao foi possivel localizar os arquivos extraidos."
    }

    Remove-RepoContentSafely -RepoRoot $repoRoot
    Copy-Item -Path (Join-Path $extractedRoot.FullName "*") -Destination $repoRoot -Recurse -Force

    Set-Content -LiteralPath $lastSyncFile -Value $remoteSha -NoNewline
    Write-Host "Sincronizacao concluida com sucesso." -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
