$ErrorActionPreference = "Continue"
Write-Host "=== Cleaning leftover Docker directories ===" -ForegroundColor Cyan

$paths = @(
    "C:\Program Files\Docker\Docker.staging",
    "C:\Program Files\Docker\Docker",
    "C:\Program Files\Docker"
)
foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p) {
        Write-Host "Removing $p ..."
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Continue
    } else {
        Write-Host "Not present: $p"
    }
}

Write-Host ""
Write-Host "=== Launching Docker Desktop installer (silent) ===" -ForegroundColor Cyan
$installer = "$env:TEMP\DockerDesktopInstaller.exe"
if (-not (Test-Path $installer)) {
    Write-Host "Installer missing at $installer" -ForegroundColor Red
    exit 2
}

$proc = Start-Process -FilePath $installer `
    -ArgumentList "install","--quiet","--accept-license","--backend=wsl-2" `
    -PassThru -Wait
Write-Host ""
Write-Host "Installer exit code: $($proc.ExitCode)" -ForegroundColor Yellow

Write-Host ""
Write-Host "=== Post-install check ===" -ForegroundColor Cyan
$dockerCli = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if (Test-Path $dockerCli) {
    Write-Host "docker.exe present at $dockerCli" -ForegroundColor Green
} else {
    Write-Host "docker.exe NOT found at expected location" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press Enter to close this window..."
Read-Host | Out-Null
