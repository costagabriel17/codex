$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Cole o token do GitHub quando o prompt pedir." -ForegroundColor Cyan
$secureToken = Read-Host "Token do GitHub" -AsSecureString

$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)

try {
    $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
}

if ([string]::IsNullOrWhiteSpace($plainToken)) {
    throw "Nenhum token foi informado."
}

[Environment]::SetEnvironmentVariable("GH_TOKEN", $plainToken, "User")
$env:GH_TOKEN = $plainToken

Write-Host ""
Write-Host "GH_TOKEN salvo com sucesso nesta maquina." -ForegroundColor Green
Write-Host "Agora voce ja pode usar o script de publicacao." -ForegroundColor Green
