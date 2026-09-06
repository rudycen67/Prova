<#
    ripara-wsl-usb.ps1
    ------------------
    Diagnostica e ripara il passaggio USB -> WSL per il Proxmark3, quando
    usbipd dice "Attached" ma dentro Ubuntu non compare nulla.

    Cosa fa (in automatico, una volta sola):
      [1] mostra il kernel di WSL (segnala kernel personalizzati senza USB/IP)
      [2] legge .wslconfig: se c'e' networkingMode=mirrored applica il fix
          documentato del firewall Hyper-V; segnala un eventuale kernel custom
      [3] garantisce la regola firewall per usbipd (porta TCP 3240)
      [4] ferma eventuali auto-attach, stacca e ri-condivide (bind) il device
      [5] riavvia WSL pulito, tiene Ubuntu accesa, aggancia il device
      [6] verifica DENTRO Ubuntu (carica cdc_acm, lsusb, /dev/ttyACM*);
          se non compare, riprova con --host-ip esplicito
      [7] stampa un REPORT completo: copialo e incollalo in chat.

    Esegui con: tasto destro > "Esegui con PowerShell" (si auto-eleva).
#>

$ErrorActionPreference = 'SilentlyContinue'
$HardwareId = '9ac4:4b8f'
$TaskName   = 'Proxmark3-WSL-AutoAttach'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
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

# Esegue un comando dentro WSL (distro predefinita) e restituisce il testo
function Invoke-Wsl([string]$cmd, [switch]$Root) {
    $wslArgs = @()
    if ($Root) { $wslArgs += @('-u','root') }
    $wslArgs += @('-e','sh','-c',$cmd)
    $out = & wsl @wslArgs 2>&1 | Out-String
    return $out.Trim()
}

# Verifica se il Proxmark3 e' visibile dentro WSL
function Test-DeviceInWsl {
    Invoke-Wsl 'modprobe cdc_acm 2>/dev/null; true' -Root | Out-Null
    $out = Invoke-Wsl 'lsusb 2>/dev/null; ls /dev/ttyACM* 2>/dev/null'
    return @{ Ok = ($out -match $HardwareId -or $out -match 'ttyACM'); Text = $out }
}

Write-Host "================= REPORT RIPARAZIONE USB -> WSL =================" -ForegroundColor Cyan
Write-Host "Data: $(Get-Date)"
Write-Host ""

# ---------- [1] Kernel ----------
$kernel = Invoke-Wsl 'uname -r'
Write-Host "[1] Kernel WSL: $kernel"
if ($kernel -notmatch 'microsoft') {
    Write-Host "    !! Kernel NON Microsoft (personalizzato): potrebbe mancare USB/IP." -ForegroundColor Yellow
}
Write-Host "    Distribuzioni:"
(& wsl -l -v 2>&1 | Out-String).Trim() -split "`r?`n" | ForEach-Object { Write-Host "      $_" }
Write-Host ""

# ---------- [2] .wslconfig ----------
$mirrored = $false
$cfg = Join-Path $env:USERPROFILE '.wslconfig'
if (Test-Path $cfg) {
    $txt = Get-Content $cfg -Raw
    Write-Host "[2] .wslconfig ($cfg):"
    ($txt -split "`r?`n") | ForEach-Object { Write-Host "      $_" }
    if ($txt -match 'networkingMode\s*=\s*mirrored') {
        $mirrored = $true
        Write-Host "    !! networkingMode=mirrored: causa nota di 'Attached ma invisibile'." -ForegroundColor Yellow
        Write-Host "       Applico il fix firewall Hyper-V (documentato da usbipd)..." -ForegroundColor Yellow
        try {
            Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow -ErrorAction Stop
            Write-Host "       fix Hyper-V firewall applicato." -ForegroundColor Green
        } catch { Write-Host "       (Set-NetFirewallHyperVVMSetting non disponibile su questo Windows)" -ForegroundColor DarkGray }
    }
    if ($txt -match '(?m)^\s*kernel\s*=') {
        Write-Host "    !! E' impostato un kernel personalizzato (riga 'kernel='): puo' mancare USB/IP." -ForegroundColor Yellow
    }
} else {
    Write-Host "[2] .wslconfig: assente (impostazioni predefinite, ok)."
}
Write-Host ""

# ---------- [3] Firewall usbipd ----------
$rule = Get-NetFirewallRule -DisplayName '*usbipd*' -ErrorAction SilentlyContinue
if ($rule) {
    Write-Host "[3] Regola firewall usbipd: presente."
} else {
    Write-Host "[3] Regola firewall usbipd assente: la creo (TCP 3240 in ingresso)." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName 'usbipd (USB/IP 3240)' -Direction Inbound -Protocol TCP -LocalPort 3240 -Action Allow | Out-Null
}
Write-Host ""

# ---------- [4] usbipd, auto-attach, bind ----------
$usbipd = Get-Usbipd
if (-not $usbipd) {
    Write-Host "[4] usbipd NON installato. Installa usbipd-win e rilancia." -ForegroundColor Red
    Read-Host "Premi Invio per chiudere"; return
}
Write-Host "[4] usbipd: $usbipd"
Stop-ScheduledTask    -TaskName $TaskName -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Out-Null
$list = (& $usbipd list 2>&1 | Out-String)
Write-Host "    usbipd list (prima):"
($list -split "`r?`n") | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "      $_" }
$line = ($list -split "`r?`n") | Where-Object { $_ -match $HardwareId } | Select-Object -First 1
if (-not $line) {
    Write-Host "    !! Proxmark3 ($HardwareId) NON collegato. Collegalo e rilancia." -ForegroundColor Red
    Read-Host "Premi Invio per chiudere"; return
}
if ($line -match 'Attached')   { & $usbipd detach --hardware-id $HardwareId | Out-Null; Start-Sleep 2 }
if ($line -match 'Not shared') { & $usbipd bind   --hardware-id $HardwareId | Out-Null }
Write-Host ""

# ---------- [5] Riavvio WSL pulito + attach ----------
Write-Host "[5] Riavvio WSL pulito e aggancio del device..."
& wsl --shutdown
Start-Sleep 3
# tiene Ubuntu accesa per tutta la verifica
Start-Process -FilePath 'wsl' -ArgumentList '-e','sleep','300' -WindowStyle Hidden
Start-Sleep 4
$att = (& $usbipd attach --wsl --hardware-id $HardwareId 2>&1 | Out-String).Trim()
Write-Host "    attach: $(if ($att) { $att } else { 'ok (nessun messaggio)' })"
Start-Sleep 4
Write-Host ""

# ---------- [6] Verifica dentro WSL ----------
$chk = Test-DeviceInWsl
Write-Host "[6] Dentro Ubuntu (lsusb + /dev/ttyACM*):"
if ($chk.Text) { ($chk.Text -split "`r?`n") | ForEach-Object { Write-Host "      $_" } } else { Write-Host "      (vuoto)" }

if (-not $chk.Ok) {
    # secondo tentativo: IP host esplicito (utile con mirrored / VPN / piu' schede)
    $ip = (Get-NetIPAddress -InterfaceAlias '*WSL*' -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress | Select-Object -First 1
    if ($ip) {
        Write-Host "    Non visibile: riprovo con --host-ip $ip ..." -ForegroundColor Yellow
        & $usbipd detach --hardware-id $HardwareId | Out-Null
        Start-Sleep 2
        $att2 = (& $usbipd attach --wsl --hardware-id $HardwareId --host-ip $ip 2>&1 | Out-String).Trim()
        Write-Host "    attach (host-ip): $(if ($att2) { $att2 } else { 'ok' })"
        Start-Sleep 4
        $chk = Test-DeviceInWsl
        Write-Host "    Dentro Ubuntu (2o tentativo):"
        if ($chk.Text) { ($chk.Text -split "`r?`n") | ForEach-Object { Write-Host "      $_" } } else { Write-Host "      (vuoto)" }
    } else {
        Write-Host "    (nessuna scheda 'vEthernet (WSL)' trovata: probabile mirrored/VPN)" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ---------- [7] Verdetto ----------
Write-Host "==================================================================" -ForegroundColor Cyan
if ($chk.Ok) {
    Write-Host " OK: il Proxmark3 E' VISIBILE in Ubuntu." -ForegroundColor Green
    Write-Host " Ora rendilo automatico: esegui  install-all.ps1  (Windows) e" -ForegroundColor Green
    Write-Host " bash wsl/auto-seriale.sh  (Ubuntu), poi  wsl --shutdown  una volta." -ForegroundColor Green
} else {
    Write-Host " NON ANCORA VISIBILE. Copia TUTTO questo report e incollalo in chat:" -ForegroundColor Red
    Write-Host " con kernel, .wslconfig e i tentativi di attach si capisce la causa." -ForegroundColor Red
}
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Premi Invio per chiudere (prima seleziona e copia tutto il testo qui sopra)"
