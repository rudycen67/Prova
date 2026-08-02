<#
    2-attach-proxmark3.ps1
    ----------------------
    Aggancia il Proxmark3 a WSL2.

    - Esegue il "bind" (condivisione persistente, una tantum, richiede admin).
    - Avvia l'attach AUTOMATICO: ogni volta che il Proxmark3 viene collegato
      alla USB, viene ri-agganciato a WSL senza interventi manuali.

    Il processo resta in esecuzione (premi Ctrl+C per fermarlo). Per renderlo
    automatico all'avvio di Windows usa 3-setup-autostart.ps1.
#>

$ErrorActionPreference = 'Stop'

# VID:PID standard del Proxmark3 (RDV4, PM3 Easy, EVO, cloni...).
$HardwareId = '9ac4:4b8f'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 1) usbipd installato?
if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
    Write-Error "usbipd non trovato. Esegui prima 1-install-usbipd.ps1"
    return
}

# 2) Il Proxmark3 e' collegato?
$list = usbipd list
if ($list -notmatch $HardwareId) {
    Write-Warning "Proxmark3 ($HardwareId) non rilevato tra i dispositivi USB."
    Write-Host   "Collega il Proxmark3 alla porta USB e rilancia questo script." -ForegroundColor Yellow
    Write-Host   "Dispositivi attuali:`n$list"
    return
}

# 3) BIND persistente (serve una volta sola, richiede admin).
$deviceLine = ($list -split "`r?`n") | Where-Object { $_ -match $HardwareId } | Select-Object -First 1
if ($deviceLine -match 'Not shared') {
    if (-not (Test-Admin)) {
        Write-Host "Serve il bind iniziale (privilegi di amministratore). Rilancio elevato..." -ForegroundColor Yellow
        Start-Process -Verb RunAs -FilePath 'powershell' `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        return
    }
    Write-Host "==> Eseguo il bind del Proxmark3 ($HardwareId)..." -ForegroundColor Cyan
    usbipd bind --hardware-id $HardwareId
    Write-Host "Bind completato (persistente)." -ForegroundColor Green
}
else {
    Write-Host "Il Proxmark3 risulta gia' condiviso (bind gia' fatto)." -ForegroundColor Green
}

# 4) ATTACH automatico verso WSL: resta in ascolto e ri-aggancia ad ogni
#    collegamento del dispositivo. Non richiede privilegi di amministratore.
Write-Host ""
Write-Host "==> Avvio auto-attach del Proxmark3 verso WSL." -ForegroundColor Cyan
Write-Host "    Da ora, ogni volta che colleghi il device viene agganciato a WSL." -ForegroundColor Cyan
Write-Host "    (Ctrl+C per interrompere)" -ForegroundColor DarkGray
usbipd attach --wsl --auto-attach --hardware-id $HardwareId
