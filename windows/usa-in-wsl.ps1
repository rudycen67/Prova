<#
    usa-in-wsl.ps1
    --------------
    Riporta il Proxmark3 all'uso in WSL (Ubuntu), riattivando l'auto-attach.
    Da usare dopo aver finito con il client nativo di Windows.
#>

$ErrorActionPreference = 'SilentlyContinue'
$TaskName = 'Proxmark3-WSL-AutoAttach'

Write-Host "==> Riattivo l'auto-attach verso WSL..." -ForegroundColor Cyan
Enable-ScheduledTask -TaskName $TaskName | Out-Null
Start-ScheduledTask  -TaskName $TaskName

Write-Host ""
Write-Host "Auto-attach riattivato." -ForegroundColor Green
Write-Host "Ricollega (o riattacca) il Proxmark3: tornera' visibile in Ubuntu come /dev/ttyACM0." -ForegroundColor Green
Write-Host "Se non compare subito, in PowerShell:  usbipd attach --wsl --hardware-id 9ac4:4b8f" -ForegroundColor DarkGray
