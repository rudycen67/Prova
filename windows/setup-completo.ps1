<#
    setup-completo.ps1
    ------------------
    Configurazione COMPLETA in un unico avvio.

    FASE 1 (Windows): installa usbipd-win, esegue il bind del Proxmark3 e attiva
                      l'auto-attach permanente (attivita' pianificata + demone).
    FASE 2 (WSL):     compila e installa il client Proxmark3 dentro Ubuntu.

    Ti verranno chiesti solo:
      - il consenso UAC (una volta), per il passaggio da amministratore;
      - la password 'sudo' di Ubuntu, per installare le dipendenze in WSL.

    Prerequisiti: Windows 10/11 con WSL2 + Ubuntu gia' installati e il Proxmark3
    COLLEGATO alla USB prima di avviare.

    Suggerimento: puoi anche fare doppio clic sul file SETUP.cmd nella cartella
    principale del progetto.
#>

$ErrorActionPreference = 'Stop'
$HardwareId = '9ac4:4b8f'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si auto-eleva: l'unico consenso richiesto (UAC), una volta sola.
if (-not (Test-Admin)) {
    Write-Host "Serve un solo consenso da amministratore. Rilancio elevato..." -ForegroundColor Yellow
    Start-Process -Verb RunAs -FilePath 'powershell' `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    return
}

function Get-Usbipd {
    $c = Get-Command usbipd -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:ProgramFiles 'usbipd-win\usbipd.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'usbipd-win\usbipd.exe')
    )) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

try {
    $here     = $PSScriptRoot
    $repoRoot = Split-Path $here -Parent

    # ---------------------------------------------------------------------
    # FASE 1 — Windows
    # ---------------------------------------------------------------------
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " FASE 1/2 - Configurazione Windows (usbipd + auto-attach)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    & (Join-Path $here 'install-all.ps1')

    # Verifica che il device sia effettivamente condiviso/agganciato
    $usbipd = Get-Usbipd
    $line = $null
    if ($usbipd) {
        $line = (& $usbipd list) -split "`r?`n" |
                Where-Object { $_ -match $HardwareId } | Select-Object -First 1
    }
    if (-not $line -or ($line -match 'Not shared')) {
        Write-Warning "Configurazione Windows non completata (Proxmark3 non agganciato)."
        Write-Host   "Collega il Proxmark3 e riavvia SETUP.cmd. Salto la FASE 2." -ForegroundColor Yellow
        return
    }

    # ---------------------------------------------------------------------
    # FASE 2 — WSL (compilazione client)
    # ---------------------------------------------------------------------
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " FASE 2/2 - Compilazione client dentro Ubuntu/WSL" -ForegroundColor Cyan
    Write-Host " (potrebbe chiedere la password sudo di Ubuntu)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Warning "Comando 'wsl' non trovato: WSL non risulta installato. Salto la FASE 2."
        Write-Host   "Installa WSL2 + Ubuntu, poi esegui a mano: wsl/setup.sh" -ForegroundColor Yellow
        return
    }

    # Converte il percorso Windows del repo in percorso WSL (/mnt/<lettera>/...)
    if ($repoRoot -match '^[A-Za-z]:\\') {
        $drive   = $repoRoot.Substring(0,1).ToLower()
        $wslRepo = "/mnt/$drive" + (($repoRoot.Substring(2)) -replace '\\','/')
    } else {
        Write-Warning "Percorso repo non su unita' locale ($repoRoot): salto la FASE 2."
        Write-Host   "Esegui a mano dentro Ubuntu: bash <percorso>/wsl/setup.sh" -ForegroundColor Yellow
        return
    }
    # Uso build-matching-client.sh: compila un client IDENTICO al firmware
    # attualmente installato sul device (legge la versione e si allinea al commit).
    $buildSh = "$wslRepo/wsl/build-matching-client.sh"
    $checkSh = "$wslRepo/wsl/check-firmware.sh"

    # Assicura che il device sia agganciato ALLA STESSA istanza WSL che eseguira'
    # la build (l'attach va fatto nello stesso contesto, non basta il 'bind').
    Write-Host "==> Aggancio il Proxmark3 a WSL e attendo /dev/ttyACM*..." -ForegroundColor Cyan
    $devReady = $false
    for ($i = 0; $i -lt 15; $i++) {
        & $usbipd attach --wsl --hardware-id $HardwareId 2>$null
        $probe = & wsl -e bash -lc "ls /dev/ttyACM* 2>/dev/null | head -n1"
        if ($probe) { $devReady = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $devReady) {
        Write-Warning "Il Proxmark3 non compare in WSL (/dev/ttyACM*)."
        Write-Host   "Sblocco manuale:" -ForegroundColor Yellow
        Write-Host   "  1) Apri Ubuntu normalmente e prova:  lsusb ; ls /dev/ttyACM*" -ForegroundColor Yellow
        Write-Host   "  2) Se serve, in PowerShell:  usbipd attach --wsl --hardware-id $HardwareId" -ForegroundColor Yellow
        Write-Host   "  3) Se lsusb lo vede ma manca ttyACM:  sudo modprobe cdc_acm" -ForegroundColor Yellow
        Write-Host   "  4) Poi builda:  bash '$buildSh'" -ForegroundColor Yellow
        return
    }
    Write-Host "    Device visibile in WSL su: $probe" -ForegroundColor Green

    Write-Host "==> Compilo un client identico al firmware installato: $buildSh" -ForegroundColor DarkGray
    Write-Host "    (legge la versione dal device e si allinea al suo commit)" -ForegroundColor DarkGray
    & wsl -e bash -lc "bash '$buildSh'"
    $buildRc = $LASTEXITCODE

    if ($buildRc -ne 0) {
        Write-Warning "La compilazione in WSL e' terminata con codice $buildRc. Vedi i messaggi sopra."
        Write-Host   "Puoi ritentarla dentro Ubuntu con: bash '$buildSh'" -ForegroundColor Yellow
        return
    }

    Write-Host "Client compilato e installato in WSL." -ForegroundColor Green
    Write-Host "==> Riavvio WSL per applicare i permessi seriali (dialout)..." -ForegroundColor Cyan
    & wsl --shutdown

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " TUTTO PRONTO." -ForegroundColor Green
    Write-Host " Da ora colleghi il Proxmark3 e lo trovi in Ubuntu da solo." -ForegroundColor Green
    Write-Host ""
    Write-Host " In Ubuntu, per verificare/usare il device:" -ForegroundColor Cyan
    Write-Host "     bash '$checkSh'"
    Write-Host "     pm3"
    Write-Host "==================================================" -ForegroundColor Green
}
finally {
    Write-Host ""
    Read-Host "Premi Invio per chiudere questa finestra"
}
