<#
    install-all.ps1
    ---------------
    CONFIGURAZIONE UNICA (da eseguire UNA SOLA VOLTA, con il Proxmark3 collegato).

    Fa tutto in un colpo solo:
      1) installa usbipd-win se manca;
      2) esegue il "bind" del Proxmark3 (l'unica operazione che richiede admin);
      3) registra un'attivita' pianificata che, ad ogni login di Windows, avvia
         in background il demone di auto-attach;
      4) avvia subito il demone.

    Da qui in poi: attacchi il Proxmark3 alla USB e viene riconosciuto in WSL
    IN AUTOMATICO, senza lanciare piu' nulla.

    Come si usa:
      - Collega il Proxmark3 alla USB.
      - Tasto destro su questo file > "Esegui con PowerShell"  (accetta l'UAC),
        oppure in PowerShell:  ./install-all.ps1
#>

$ErrorActionPreference = 'Stop'
$HardwareId   = '9ac4:4b8f'        # VID:PID standard del Proxmark3
$TaskName     = 'Proxmark3-WSL-AutoAttach'
$DaemonSource = Join-Path $PSScriptRoot '_auto-attach-daemon.ps1'
# Cartella stabile per-utente: il task punta qui, così resta valido anche se
# sposti o cancelli la cartella del repo -> automazione davvero permanente.
$StableDir    = Join-Path $env:LOCALAPPDATA 'Proxmark3-WSL'
$DaemonPath   = Join-Path $StableDir '_auto-attach-daemon.ps1'

# --- Elevazione automatica a amministratore (serve per il bind) --------------
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
    Write-Host "Serve un solo passaggio da amministratore. Rilancio con elevazione..." -ForegroundColor Yellow
    Start-Process -Verb RunAs -FilePath 'powershell' `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    return
}

# --- Helper: individua usbipd (anche se non ancora nel PATH) ------------------
function Get-Usbipd {
    $c = Get-Command usbipd -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:ProgramFiles 'usbipd-win\usbipd.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'usbipd-win\usbipd.exe')
    )) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

# --- 1) Installa usbipd-win se manca -----------------------------------------
$usbipd = Get-Usbipd
if (-not $usbipd) {
    Write-Host "==> Installo usbipd-win..." -ForegroundColor Cyan
    winget install --interactive --exact dorssel.usbipd-win `
        --accept-package-agreements --accept-source-agreements
    $usbipd = Get-Usbipd
}
if (-not $usbipd) {
    Write-Error "usbipd non trovato dopo l'installazione. Chiudi e riapri PowerShell, poi rilancia questo script."
    return
}
Write-Host "usbipd: $usbipd" -ForegroundColor DarkGray

# --- 2) Bind del Proxmark3 (device deve essere collegato) --------------------
$list = & $usbipd list
if ($list -notmatch $HardwareId) {
    Write-Warning "Proxmark3 ($HardwareId) non rilevato tra i dispositivi USB."
    Write-Host   "Collega il Proxmark3 alla porta USB e rilancia questo script." -ForegroundColor Yellow
    Write-Host   "`nDispositivi attuali:`n$list"
    return
}
$deviceLine = ($list -split "`r?`n") | Where-Object { $_ -match $HardwareId } | Select-Object -First 1
if ($deviceLine -match 'Not shared') {
    Write-Host "==> Eseguo il bind del Proxmark3 (persistente)..." -ForegroundColor Cyan
    & $usbipd bind --hardware-id $HardwareId
    Write-Host "Bind completato." -ForegroundColor Green
} else {
    Write-Host "Il Proxmark3 risulta gia' condiviso (bind gia' fatto)." -ForegroundColor Green
}

# --- 3) Copia il demone in una cartella stabile ------------------------------
if (-not (Test-Path $DaemonSource)) { Write-Error "Non trovo $DaemonSource"; return }
New-Item -ItemType Directory -Path $StableDir -Force | Out-Null
Copy-Item -Path $DaemonSource -Destination $DaemonPath -Force
Write-Host "==> Demone installato in: $DaemonPath" -ForegroundColor DarkGray

# --- 4) Attivita' pianificata: avvia il demone ad ogni login -----------------
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$DaemonPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal -Force | Out-Null
Write-Host "==> Attivita' pianificata '$TaskName' registrata." -ForegroundColor Green

# --- 5) Avvia subito il demone (senza aspettare il prossimo login) -----------
Start-ScheduledTask -TaskName $TaskName
Write-Host "==> Demone di auto-attach avviato." -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " CONFIGURAZIONE COMPLETATA." -ForegroundColor Green
Write-Host " Da ora attacchi il Proxmark3 e viene riconosciuto in WSL"      -ForegroundColor Green
Write-Host " in automatico, senza lanciare nulla."                          -ForegroundColor Green
Write-Host ""
Write-Host " In Ubuntu/WSL, la prima volta, compila il client:"            -ForegroundColor Cyan
Write-Host "     cd wsl && chmod +x *.sh && ./setup.sh"
Write-Host " Poi verifica il device con:  ./check-firmware.sh"
Write-Host "============================================================" -ForegroundColor Green
