# Proxmark3 su Ubuntu (WSL2) — setup automatico

Questo repository contiene tutto il necessario per usare un **Proxmark3** dentro
**Ubuntu su WSL2 (Windows)**, con l'obiettivo che, dopo una configurazione
iniziale una-tantum, il flusso sia:

> **Colleghi il Proxmark3 alla USB → Windows lo aggancia da solo a WSL → entri in Ubuntu e sei operativo.**

Include anche uno script che **verifica il firmware presente sul dispositivo** e
ti dice quale client/piattaforma usare.

Il motivo per cui serve una configurazione è che **WSL2 gira in una VM leggera e
non vede direttamente le porte USB**: bisogna "passare" il dispositivo da Windows
a WSL con lo strumento [`usbipd-win`](https://github.com/dorssel/usbipd-win).

---

## Struttura

```
windows/   → script PowerShell (lato Windows host)
  1-install-usbipd.ps1     installa usbipd-win
  2-attach-proxmark3.ps1   bind + auto-attach del device verso WSL
  3-setup-autostart.ps1    rende l'auto-attach automatico ad ogni login

wsl/       → script Bash (dentro Ubuntu/WSL)
  setup.sh            installa dipendenze e compila il client (Iceman/RRG)
  check-firmware.sh   legge il firmware del device e indica il client giusto
  pm3-connect.sh      wrapper comodo per connettersi

docs/
  guida-completa.md   guida dettagliata passo-passo con note e troubleshooting
```

---

## Configurazione iniziale (una sola volta)

### Su Windows (PowerShell **come Amministratore**)

```powershell
cd windows
./1-install-usbipd.ps1      # installa usbipd-win (poi riapri PowerShell)
./2-attach-proxmark3.ps1    # bind (admin) + avvia l'auto-attach
./3-setup-autostart.ps1     # rende l'auto-attach automatico ad ogni login
```

### Dentro Ubuntu/WSL

```bash
cd wsl
chmod +x *.sh
./setup.sh                  # dipendenze + compilazione client (qualche minuto)
#   per il Proxmark3 RDV4:  PLATFORM=PM3RDV4 ./setup.sh
```

Poi da PowerShell riavvia WSL una volta: `wsl --shutdown` (serve per applicare il
gruppo `dialout`).

---

## Uso quotidiano

1. Colleghi il Proxmark3 alla USB (Windows lo aggancia a WSL da solo).
2. Apri Ubuntu.
3. Verifica il firmware / client corretto:
   ```bash
   cd wsl && ./check-firmware.sh
   ```
4. Connettiti:
   ```bash
   pm3            # oppure ./pm3-connect.sh
   ```
   Al prompt `[usb] pm3 -->` prova `hw status` o `lf search` / `hf search`.

---

## Note importanti

- Il **bind** (condivisione USB) è persistente: si fa una volta. L'**attach** è
  gestito in automatico dallo script/attività pianificata.
- **Flash del firmware da WSL**: durante il flash il device passa in modalità
  bootloader e *cambia porta* (ttyACM0 ⇄ ttyACM1), staccandosi da WSL. Per
  aggiornare il firmware conviene farlo da Windows nativo oppure ricollegare
  rapidamente il device. Per leggere/testare tag WSL va benissimo.

Dettagli, spiegazioni e troubleshooting completo in
[`docs/guida-completa.md`](docs/guida-completa.md).
