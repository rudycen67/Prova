<#
    1-install-usbipd.ps1
    --------------------
    Installa "usbipd-win", lo strumento che permette di passare (condividere)
    un dispositivo USB dal Windows host verso WSL2.

    Esegui UNA SOLA VOLTA, in PowerShell come Amministratore.
#>

$ErrorActionPreference = 'Stop'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Warning "Questo script va eseguito come Amministratore."
    Write-Host   "Rilancio con elevazione dei privilegi..." -ForegroundColor Yellow
    Start-Process -Verb RunAs -FilePath 'powershell' `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    return
}

if (Get-Command usbipd -ErrorAction SilentlyContinue) {
    Write-Host "usbipd risulta gia' installato:" -ForegroundColor Green
    usbipd --version
    return
}

Write-Host "==> Installo usbipd-win tramite winget..." -ForegroundColor Cyan
winget install --interactive --exact dorssel.usbipd-win --accept-package-agreements --accept-source-agreements

Write-Host ""
Write-Host "Installazione completata." -ForegroundColor Green
Write-Host "IMPORTANTE: chiudi e riapri PowerShell prima di continuare," -ForegroundColor Yellow
Write-Host "poi esegui  2-attach-proxmark3.ps1" -ForegroundColor Yellow
