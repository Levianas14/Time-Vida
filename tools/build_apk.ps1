param([string]$Flutter = 'flutter')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (-not (Test-Path 'android/key.properties')) {
        throw 'Configure android/key.properties com uma chave de release antes de compilar. Consulte README.md.'
    }
    & $Flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter dependências.' }
    & $Flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'A análise estática falhou.' }
    & $Flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Os testes falharam.' }
    & $Flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'A compilação Android falhou.' }
    New-Item -ItemType Directory -Path 'dist' -Force | Out-Null
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination 'dist/tempo-vivo.apk'
    $hash = (Get-FileHash -LiteralPath 'dist/tempo-vivo.apk' -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText((Join-Path $projectRoot 'dist/tempo-vivo.apk.sha256'), "$hash  tempo-vivo.apk`n")
    Write-Output 'APK disponível em dist/tempo-vivo.apk'
} finally {
    Pop-Location
}
