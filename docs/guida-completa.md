# Guida completa — Proxmark3 su Ubuntu (WSL2)

Guida dettagliata per usare il Proxmark3 dentro WSL2, con spiegazioni,
automazione e troubleshooting.

## Indice
1. [Come funziona (perché serve usbipd)](#1-come-funziona)
2. [Lato Windows: installare usbipd-win](#2-lato-windows-installare-usbipd-win)
3. [Lato Windows: agganciare il Proxmark3 a WSL](#3-lato-windows-agganciare-il-proxmark3-a-wsl)
4. [Rendere l'aggancio automatico](#4-rendere-laggancio-automatico)
5. [Lato WSL: dipendenze e compilazione del client](#5-lato-wsl-dipendenze-e-compilazione-del-client)
6. [Verificare il firmware e scegliere il client giusto](#6-verificare-il-firmware)
7. [Connettersi e primi comandi](#7-connettersi)
8. [Aggiornare il firmware (flash)](#8-aggiornare-il-firmware)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Come funziona

WSL2 non è una semplice shell su Windows: è una **VM leggera** con un kernel
Linux proprio. Questo kernel **non ha accesso diretto ai controller USB** del PC.
Per usare un dispositivo USB come il Proxmark3 dentro WSL bisogna "inoltrarlo"
dal Windows host alla VM tramite il protocollo **USB/IP**, implementato su
Windows da [`usbipd-win`](https://github.com/dorssel/usbipd-win).

Il flusso è:

```
Proxmark3 (USB) → Windows host → [usbipd] → WSL2 (Ubuntu) → /dev/ttyACM0 → client pm3
```

Due operazioni chiave:
- **bind**: condivide un dispositivo USB rendendolo "inoltrabile" (persistente,
  una volta sola, richiede privilegi di amministratore).
- **attach**: aggancia effettivamente il dispositivo a WSL (da ripetere ad ogni
  collegamento — ma lo automatizziamo).

---

## 2. Lato Windows: installare usbipd-win

In **PowerShell come Amministratore**:

```powershell
winget install --interactive --exact dorssel.usbipd-win
```

Oppure esegui lo script `windows/1-install-usbipd.ps1`. Dopo l'installazione
**chiudi e riapri PowerShell**. Verifica:

```powershell
usbipd --version
```

---

## 3. Lato Windows: agganciare il Proxmark3 a WSL

Con il Proxmark3 collegato, in PowerShell (Amministratore):

```powershell
usbipd list
```

Cerca la riga del Proxmark3 — di solito con VID:PID **`9ac4:4b8f`** — e annota
il **BUSID** (es. `2-4`). Poi:

```powershell
usbipd bind --busid 2-4                 # una volta sola (persistente)
usbipd attach --wsl --busid 2-4         # aggancia a WSL
```

In alternativa, identificando il device per VID:PID (indipendente dalla porta):

```powershell
usbipd bind   --hardware-id 9ac4:4b8f
usbipd attach --wsl --hardware-id 9ac4:4b8f
```

Lo script `windows/2-attach-proxmark3.ps1` fa entrambe le cose e avvia inoltre
la modalità **`--auto-attach`**, che ri-aggancia il dispositivo automaticamente
ogni volta che lo colleghi.

> Nelle versioni molto vecchie di usbipd il comando era `usbipd wsl attach ...`.

---

## 4. Rendere l'aggancio automatico

**Metodo consigliato — un solo comando:** `windows/install-all.ps1` esegue in
un colpo solo installazione di usbipd, `bind` e registrazione+avvio del demone
di auto-attach (si auto-eleva per il solo passaggio admin). Da eseguire una
volta con il Proxmark3 collegato.

Sotto il cofano registra un'**attività pianificata** (`Proxmark3-WSL-AutoAttach`)
che, ad ogni login di Windows, avvia in background il demone
`windows/_auto-attach-daemon.ps1`. Il demone è **resiliente**: resta in ascolto
e aggancia il device anche se lo colleghi molto **dopo** l'accensione del PC (un
ciclo riprova in caso di device assente / WSL non ancora avviato). Da quel
momento:

- accendi il PC / fai login → il demone parte da solo;
- colleghi il Proxmark3 in qualsiasi momento → viene agganciato a WSL
  automaticamente, senza lanciare nulla.

Se preferisci i passi separati usa `windows/3-setup-autostart.ps1` (richiede un
`bind` già fatto, es. via `2-attach-proxmark3.ps1`).

Per avviarla subito senza riavviare:

```powershell
Start-ScheduledTask -TaskName 'Proxmark3-WSL-AutoAttach'
```

Per rimuoverla:

```powershell
Unregister-ScheduledTask -TaskName 'Proxmark3-WSL-AutoAttach' -Confirm:$false
```

---

## 5. Lato WSL: dipendenze e compilazione del client

Dentro Ubuntu, dipendenze di build del client Iceman/RRG:

```bash
sudo apt update
sudo apt install --no-install-recommends \
  git ca-certificates build-essential pkg-config \
  libreadline-dev gcc-arm-none-eabi libnewlib-dev \
  qtbase5-dev libbz2-dev libbluetooth-dev \
  libpython3-dev libssl-dev libgd-dev usbutils
```

Permessi seriali (una volta sola), poi riavvia WSL:

```bash
sudo usermod -aG dialout $USER
# da PowerShell: wsl --shutdown   (e riapri Ubuntu)
```

Clona e compila:

```bash
git clone https://github.com/RfidResearchGroup/proxmark3.git
cd proxmark3
make clean && make -j$(nproc) PLATFORM=PM3GENERIC   # PM3RDV4 per l'RDV4
sudo make install PLATFORM=PM3GENERIC
```

Tutto questo è automatizzato in `wsl/setup.sh`.

---

## 6. Verificare il firmware

Prima di usare il device conviene sapere **quale firmware ha già installato**,
così da usare il **client corretto** ed evitare mismatch di versione.

Esegui:

```bash
cd wsl && ./check-firmware.sh
```

Lo script:
1. trova il client `pm3` e la porta seriale;
2. esegue `hw version` sul dispositivo;
3. mostra **firmware (OS)**, **bootrom**, **client**, il **fork** (Iceman/RRG vs
   ufficiale) e l'**hardware** (RDV4 vs generico);
4. dice se client e firmware sono allineati e, se serve, come riallinearli.

In manuale, lo stesso lo ottieni con:

```bash
pm3 -p /dev/ttyACM0 -c 'hw version'
```

### Client identico al firmware (evita i mismatch)

Se vuoi che il client sia **identico al firmware già presente** sul device
(senza riflashare), usa:

```bash
cd wsl && ./build-matching-client.sh
```

Legge la versione dal Proxmark3, ricava il commit git del firmware, fa il
checkout di quel commit e ricompila il client su quella base: al termine client
e firmware coincidono e non compare alcun warning di `mismatch`. È lo stesso
passo che esegue in automatico `SETUP.cmd`. Nota: il client identico non è
pre-costruibile perché dipende dalla versione del *tuo* firmware (leggibile solo
a device collegato) e va comunque compilato sulla tua macchina.

Interpretazione:
- Se `os:` contiene **`Iceman`**/**`RRG`** → firmware Iceman/RRG: usa il client
  Iceman (quello compilato qui). È la configurazione consigliata.
- Se il client segnala **`mismatch`** o le versioni differiscono → riflasha il
  device alla stessa versione del client (vedi §8).
- Se compare **`RDV4`** → è un Proxmark3 RDV4: compila con `PLATFORM=PM3RDV4`.

---

## 7. Connettersi

```bash
pm3                      # rileva la porta in automatico
pm3 -p /dev/ttyACM0      # porta esplicita
./pm3-connect.sh         # wrapper incluso
```

Al prompt `[usb] pm3 -->`:

```
hw status         # stato hardware
hw version        # versioni client/firmware
lf search         # cerca un tag a bassa frequenza (125 kHz)
hf search         # cerca un tag ad alta frequenza (13.56 MHz)
```

---

## 8. Aggiornare il firmware

⚠️ **Attenzione con WSL**: durante il flash il Proxmark3 passa in modalità
bootloader e **cambia porta** (ttyACM0 ⇄ ttyACM1), staccandosi da WSL. Questo
può interrompere il flash. Opzioni:

- **Consigliata**: esegui il flash da **Windows nativo** (client Windows di
  Iceman), dove il device resta agganciato.
- Con l'**auto-attach attivo** (`windows/2-attach-proxmark3.ps1` o l'attività
  pianificata) il device viene ri-agganciato da solo quando cambia porta: è la
  via più comoda per flashare da WSL.

Script dedicato (consigliato) — verifica i prerequisiti, attende il ritorno del
device dopo il reboot in bootloader e conferma l'esito con `hw version`:

```bash
cd wsl
./flash-firmware.sh            # flash completo (bootrom + firmware)
./flash-firmware.sh --image    # solo firmware (fullimage)
./flash-firmware.sh --yes      # senza conferma interattiva
```

In manuale (dalla cartella dei sorgenti, dopo aver compilato):

```bash
cd ~/proxmark3
./pm3-flash-all          # bootrom + firmware
# oppure solo il firmware:
./pm3-flash-fullimage
```

---

## 9. Troubleshooting

**`ls /dev/ttyACM*` non mostra nulla**
- Verifica che l'attach sia attivo: da PowerShell `usbipd list` → il device deve
  risultare `Attached`.
- In WSL: `lsusb` deve mostrare il Proxmark3. Se `lsusb` lo vede ma non compare
  `/dev/ttyACM0`, prova `sudo modprobe cdc_acm`.

**`Permission denied` sulla porta**
- Manca il gruppo `dialout`: `sudo usermod -aG dialout $USER` e riavvia WSL
  (`wsl --shutdown`).

**usbipd: "device is busy" o non si aggancia**
- Chiudi eventuali istanze di `pm3` aperte. Ricollega il device. Rifai
  `usbipd attach`.

**Il client si connette ma i comandi falliscono / `mismatch`**
- Client e firmware hanno versioni diverse: riflasha il device (vedi §8) alla
  stessa versione del client, oppure ricompila il client alla versione del
  firmware.

**Dopo un riavvio del PC non funziona più**
- L'attach va rifatto ad ogni collegamento. Con `3-setup-autostart.ps1` è
  automatico; altrimenti rilancia `2-attach-proxmark3.ps1`.

**La build dice "Proxmark3 non trovato (/dev/ttyACM*)" durante SETUP.cmd**
- Il device è agganciato a una sessione WSL diversa da quella che esegue la
  build (tipico se la build parte dalla finestra con privilegi di admin, mentre
  l'auto-attach aggancia il device alla tua Ubuntu normale). Soluzione:
  1. apri **Ubuntu normalmente** e controlla `ls /dev/ttyACM*`;
  2. se manca, in **PowerShell**: `usbipd attach --wsl --hardware-id 9ac4:4b8f`
     e verifica che `usbipd list` mostri `Attached`;
  3. se `lsusb` vede il device ma manca `/dev/ttyACM0`: `sudo modprobe cdc_acm`;
  4. poi lancia la build a mano: `bash <percorso>/wsl/build-matching-client.sh`.
