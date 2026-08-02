<#
    status.ps1
    ----------
    Verifica (facoltativa) che l'automazione sia attiva e permanente.
    Mostra: stato dell'attivita' pianificata, presenza del bind e se il
    Proxmark3 risulta attualmente agganciato a WSL.

    Non serve nell'uso quotidiano: e' solo un controllo.
#>

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

Write-Host "=== Stato automazione Proxmark3 -> WSL ===" -ForegroundColor Cyan

# 1) usbipd installato?
$usbipd = Get-Usbipd
if ($usbipd) { Write-Host "[OK] usbipd installato: $usbipd" -ForegroundColor Green }
else { Write-Host "[!!] usbipd NON installato. Esegui install-all.ps1" -ForegroundColor Red; return }

# 2) Attivita' pianificata registrata e pronta?
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Host "[OK] Attivita' '$TaskName' registrata (State: $($task.State))" -ForegroundColor Green
    if ($info) { Write-Host "     Ultimo avvio: $($info.LastRunTime)" -ForegroundColor DarkGray }
} else {
    Write-Host "[!!] Attivita' '$TaskName' NON registrata. Esegui install-all.ps1" -ForegroundColor Red
}

# 3) Bind e stato del device
$line = (& $usbipd list) -split "`r?`n" | Where-Object { $_ -match $HardwareId } | Select-Object -First 1
if (-not $line) {
    Write-Host "[..] Proxmark3 non collegato in questo momento." -ForegroundColor Yellow
} elseif ($line -match 'Attached') {
    Write-Host "[OK] Proxmark3 collegato e AGGANCIATO a WSL." -ForegroundColor Green
} elseif ($line -match 'Shared') {
    Write-Host "[OK] Proxmark3 collegato, bind presente (in attesa di attach)." -ForegroundColor Green
} elseif ($line -match 'Not shared') {
    Write-Host "[!!] Proxmark3 collegato ma SENZA bind. Esegui install-all.ps1" -ForegroundColor Red
}

Write-Host "==========================================" -ForegroundColor Cyan
