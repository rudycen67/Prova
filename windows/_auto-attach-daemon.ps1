<#
    _auto-attach-daemon.ps1
    -----------------------
    Demone leggero eseguito in background (avviato dall'attivita' pianificata
    'Proxmark3-WSL-AutoAttach' ad ogni login di Windows).

    Tiene sempre pronto l'aggancio del Proxmark3 a WSL: appena colleghi il
    dispositivo alla USB (anche molto dopo l'accensione del PC) viene agganciato
    a WSL automaticamente, SENZA lanciare nulla a mano.

    Non richiede privilegi di amministratore (l'attach, a differenza del bind,
    non ne ha bisogno). Da non eseguire a mano: lo avvia l'attivita' pianificata.
#>

$ErrorActionPreference = 'SilentlyContinue'
$HardwareId = '9ac4:4b8f'   # VID:PID standard del Proxmark3

function Get-Usbipd {
    $c = Get-Command usbipd -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:ProgramFiles 'usbipd-win\usbipd.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'usbipd-win\usbipd.exe')
    )) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

$usbipd = Get-Usbipd
if (-not $usbipd) { exit 1 }

# Ciclo resiliente: 'attach --auto-attach' resta in ascolto e ri-aggancia ad
# ogni collegamento; se termina (device assente, WSL non ancora avviato, errore
# transitorio) attendiamo e riproviamo. Cosi' il collegamento viene sempre colto.
while ($true) {
    & $usbipd attach --wsl --auto-attach --hardware-id $HardwareId 2>$null
    Start-Sleep -Seconds 3
}
