param(
    [string]$Owner = "costagabriel17",
    [string]$Repo = "codex",
    [string]$Branch = "main",
    [string]$Message = "Atualiza arquivos do projeto"
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

function Get-Headers {
    if (-not $env:GH_TOKEN) {
        throw "GH_TOKEN nao encontrado. Defina um token do GitHub nesta maquina antes de publicar."
    }

    return @{
        "Authorization" = "Bearer $($env:GH_TOKEN)"
        "User-Agent" = "codex-publish-script"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
}

function Get-RemoteState {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Branch,
        [hashtable]$Headers
    )

    $branchUrl = "https://api.github.com/repos/$Owner/$Repo/branches/$Branch"

    try {
        $branchInfo = Invoke-RestMethod -Method Get -Uri $branchUrl -Headers $Headers
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 404) {
            return @{
                BranchExists = $false
                Files = @{}
            }
        }

        throw
    }

    $treeSha = $branchInfo.commit.commit.tree.sha
    $treeUrl = "https://api.github.com/repos/$Owner/$Repo/git/trees/$treeSha?recursive=1"
    $treeInfo = Invoke-RestMethod -Method Get -Uri $treeUrl -Headers $Headers

    $remoteFiles = @{}
    foreach ($item in $treeInfo.tree) {
        if ($item.type -eq "blob") {
            $remoteFiles[$item.path] = $item.sha
        }
    }

    return @{
        BranchExists = $true
        Files = $remoteFiles
    }
}

function Get-LocalFiles {
    param([string]$RepoRoot)

    $files = @{}
    $allFiles = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File

    foreach ($file in $allFiles) {
        $relativePath = $file.FullName.Substring($RepoRoot.Length).TrimStart("\")
        if ($relativePath.StartsWith(".git\")) {
            continue
        }
        if ($relativePath.StartsWith(".codex\")) {
            continue
        }

        $files[$relativePath.Replace("\", "/")] = $file.FullName
    }

    return $files
}

function Get-ContentApiUrl {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$RelativePath
    )

    $safePath = ($RelativePath -split "/") | ForEach-Object { [System.Uri]::EscapeDataString($_) }
    return "https://api.github.com/repos/$Owner/$Repo/contents/$($safePath -join "/")"
}

$repoRoot = Get-RepoRoot
$headers = Get-Headers

Write-Step "Lendo arquivos locais"
$localFiles = Get-LocalFiles -RepoRoot $repoRoot

Write-Step "Lendo arquivos ja existentes no GitHub"
$remoteState = Get-RemoteState -Owner $Owner -Repo $Repo -Branch $Branch -Headers $headers
$remoteFiles = $remoteState.Files
$branchExists = $remoteState.BranchExists

Write-Step "Removendo arquivos que nao existem mais localmente"
$remoteOnly = $remoteFiles.Keys | Where-Object { -not $localFiles.ContainsKey($_) } | Sort-Object
foreach ($relativePath in $remoteOnly) {
    $deleteBody = @{
        message = "${Message}: remove $relativePath"
        sha = $remoteFiles[$relativePath]
        branch = $Branch
    } | ConvertTo-Json

    $contentUrl = Get-ContentApiUrl -Owner $Owner -Repo $Repo -RelativePath $relativePath
    Invoke-RestMethod -Method Delete -Uri $contentUrl -Headers $headers -Body $deleteBody -ContentType "application/json"
    Write-Host "Removido do GitHub: $relativePath"
}

Write-Step "Enviando arquivos locais"
$localPaths = $localFiles.Keys | Sort-Object
foreach ($relativePath in $localPaths) {
    $filePath = $localFiles[$relativePath]
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $contentBase64 = [System.Convert]::ToBase64String($bytes)

    $body = @{
        message = "${Message}: $relativePath"
        content = $contentBase64
    }

    if ($branchExists) {
        $body.branch = $Branch
    }

    if ($remoteFiles.ContainsKey($relativePath)) {
        $body.sha = $remoteFiles[$relativePath]
    }

    $jsonBody = $body | ConvertTo-Json
    $contentUrl = Get-ContentApiUrl -Owner $Owner -Repo $Repo -RelativePath $relativePath
    Invoke-RestMethod -Method Put -Uri $contentUrl -Headers $headers -Body $jsonBody -ContentType "application/json"
    Write-Host "Publicado no GitHub: $relativePath"
    $branchExists = $true
}

Write-Host ""
Write-Host "Publicacao concluida com sucesso." -ForegroundColor Green
