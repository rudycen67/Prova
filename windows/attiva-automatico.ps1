<#
    attiva-automatico.ps1
    ---------------------
    Rende il Proxmark3 SUBITO DISPONIBILE in Ubuntu ad ogni collegamento, in un
    unico avvio. Da usare quando il device e' gia' visibile in WSL (connessione
    gia' funzionante) e vuoi solo rendere tutto automatico e permanente.

    Fa in sequenza:
      FASE 1 (Windows) - usbipd bind + auto-attach permanente al login
      FASE 2 (WSL)     - carica cdc_acm ad ogni avvio + gruppo dialout
      FASE 3           - riavvia WSL e riaggancia subito il device

    Ti verranno chiesti solo: il consenso UAC (una volta) e, se serve, la
    password sudo di Ubuntu.

    Uso: doppio clic (si auto-eleva), oppure fai doppio clic su ATTIVA-AUTOMATICO.cmd
#>

$ErrorActionPreference = 'Stop'
$HardwareId = '9ac4:4b8f'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}
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

    # ---------------- FASE 1: Windows ----------------
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " FASE 1/3 - Auto-attach permanente (Windows)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    & (Join-Path $here 'install-all.ps1')

    # ---------------- FASE 2: WSL ----------------
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " FASE 2/3 - Driver seriale automatico (Ubuntu)" -ForegroundColor Cyan
    Write-Host " (puo' chiedere la password sudo di Ubuntu)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan

    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        if ($repoRoot -match '^[A-Za-z]:\\') {
            $drive   = $repoRoot.Substring(0,1).ToLower()
            $wslRepo = "/mnt/$drive" + (($repoRoot.Substring(2)) -replace '\\','/')
            $autoSh  = "$wslRepo/wsl/auto-seriale.sh"
            Write-Host "==> Eseguo: $autoSh" -ForegroundColor DarkGray
            & wsl -e bash -lc "bash '$autoSh'"
        } else {
            Write-Warning "Percorso repo non su unita' locale: esegui a mano  bash wsl/auto-seriale.sh"
        }

        # ---------------- FASE 3: riavvio + attach ----------------
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host " FASE 3/3 - Riavvio WSL e aggancio del device" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        & wsl --shutdown
        Start-Sleep 3
        # sveglia WSL
        Start-Process -FilePath 'wsl' -ArgumentList '-e','true' -WindowStyle Hidden
        Start-Sleep 4
        $usbipd = Get-Usbipd
        if ($usbipd) {
            $line = (& $usbipd list 2>&1 | Out-String) -split "`r?`n" |
                    Where-Object { $_ -match $HardwareId } | Select-Object -First 1
            if ($line -match 'Not shared') { & $usbipd bind --hardware-id $HardwareId 2>$null }
            & $usbipd attach --wsl --hardware-id $HardwareId 2>$null
        }
    } else {
        Write-Warning "Comando 'wsl' non trovato: salto FASE 2 e 3."
    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " TUTTO PRONTO E AUTOMATICO." -ForegroundColor Green
    Write-Host " Da ora colleghi il Proxmark3 e lo trovi in Ubuntu" -ForegroundColor Green
    Write-Host " come /dev/ttyACM0, senza fare nulla." -ForegroundColor Green
    Write-Host ""
    Write-Host " NON disattivare l'eccezione di Bitdefender per usbipd." -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Green
}
finally {
    Write-Host ""
    Read-Host "Premi Invio per chiudere questa finestra"
}
