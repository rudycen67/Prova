<#
    3-setup-autostart.ps1
    ---------------------
    Rende l'auto-attach del Proxmark3 completamente automatico: registra
    un'attivita' pianificata che, ad ogni accesso a Windows, avvia in background
    2-attach-proxmark3.ps1 (auto-attach in ascolto).

    Prerequisito: aver gia' eseguito una volta il "bind" (vedi 2-attach-proxmark3.ps1).
    Esegui questo script UNA SOLA VOLTA.
#>

$ErrorActionPreference = 'Stop'

$TaskName   = 'Proxmark3-WSL-AutoAttach'
$scriptPath = Join-Path $PSScriptRoot '2-attach-proxmark3.ps1'

if (-not (Test-Path $scriptPath)) {
    Write-Error "Non trovo $scriptPath"
    return
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal -Force | Out-Null

Write-Host "Attivita' pianificata '$TaskName' registrata." -ForegroundColor Green
Write-Host "Da ora, ad ogni login di Windows, il Proxmark3 verra' agganciato a WSL in automatico." -ForegroundColor Green
Write-Host ""
Write-Host "Per avviarla subito senza riavviare:" -ForegroundColor Cyan
Write-Host "    Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Per rimuoverla in futuro:" -ForegroundColor DarkGray
Write-Host "    Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
