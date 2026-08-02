<#
    usa-in-windows.ps1
    ------------------
    Passa il Proxmark3 all'uso NATIVO di Windows (lo toglie da WSL).

    Necessario perche' l'auto-attach lo aggancia automaticamente a WSL: per usare
    il client nativo di Windows il device deve restare come porta COM in Windows.

    Cosa fa:
      1) ferma e disabilita temporaneamente l'attivita' di auto-attach;
      2) stacca il Proxmark3 da WSL (torna visibile come COMx in Windows).

    Per tornare a usarlo in WSL: esegui  usa-in-wsl.ps1
#>

$ErrorActionPreference = 'SilentlyContinue'
$HardwareId = '9ac4:4b8f'
$TaskName   = 'Proxmark3-WSL-AutoAttach'

function Get-Usbipd {
    $c = Get-Command usbipd -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:ProgramFiles 'usbipd-win\usbipd.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'usbipd-win\usbipd.exe')
    )) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

Write-Host "==> Fermo l'auto-attach verso WSL..." -ForegroundColor Cyan
Stop-ScheduledTask    -TaskName $TaskName
Disable-ScheduledTask -TaskName $TaskName | Out-Null

$usbipd = Get-Usbipd
if ($usbipd) {
    Write-Host "==> Stacco il Proxmark3 da WSL..." -ForegroundColor Cyan
    & $usbipd detach --hardware-id $HardwareId
}

Write-Host ""
Write-Host "Proxmark3 ora disponibile in WINDOWS come porta COM." -ForegroundColor Green
Write-Host "Trova il numero della porta in 'Gestione dispositivi' > Porte (COM e LPT)," -ForegroundColor Green
Write-Host "oppure con:  usbipd list   (la riga 9ac4:4b8f mostra COMx e stato NON 'Attached')." -ForegroundColor Green
Write-Host ""
Write-Host "Per tornare a usarlo in WSL:  usa-in-wsl.ps1" -ForegroundColor DarkGray
