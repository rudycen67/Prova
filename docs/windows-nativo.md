# Client Iceman nativo su Windows (letture LF affidabili)

Il tunnel USB-over-IP di WSL (`usbipd`) è comodo per i comandi, ma poco affidabile
per i **trasferimenti pesanti** (letture LF, dump). Per leggere/clonare tessere in
modo affidabile conviene il **client Iceman compilato nativamente su Windows**, con
il Proxmark3 collegato **direttamente** come porta COM (niente tunnel).

Questa guida costruisce un client **identico al firmware** del tuo device
(commit del tuo RDV4: **`72b1b17a3`**, versione `v4.20469`, `PLATFORM=PM3RDV4`).

---

## Passo 0 — Sposta il Proxmark3 su Windows

L'auto-attach lo aggancia a WSL: prima va liberato. In **PowerShell**:

```powershell
cd <cartella-del-progetto>\windows
./usa-in-windows.ps1
```

Questo ferma l'auto-attach e stacca il device da WSL. Ora il Proxmark3 è una
**porta COM** in Windows.

Trova il numero della porta:
- **Gestione dispositivi** → *Porte (COM e LPT)* → cerca il dispositivo seriale, oppure
- `usbipd list` → la riga `9ac4:4b8f` mostra `COMx` e lo stato **non** più `Attached`.

Nel tuo caso in precedenza era **COM7**.

> Per tornare a usarlo in WSL in futuro: `./usa-in-wsl.ps1`

---

## Passo 1 — Installa ProxSpace (ambiente di build per Windows)

1. Scarica ProxSpace: https://github.com/Gator96100/ProxSpace/releases
   (l'archivio più recente, es. `proxspace-x64.7z`).
2. Estrai in un percorso **SENZA spazi**, ad esempio `C:\ProxSpace`
   (serve 7-Zip per gli archivi `.7z`).

> Percorsi con spazi (es. Desktop, Documenti) fanno fallire la build: usa `C:\ProxSpace`.

---

## Passo 2 — Compila il client identico al firmware

1. In `C:\ProxSpace` fai doppio clic su **`runme64.bat`**: si apre una shell
   (prompt tipo `[PS] >`).
2. Nella shell, esegui:

```bash
cd /pm3
git clone https://github.com/RfidResearchGroup/proxmark3.git
cd proxmark3
git checkout 72b1b17a3          # allinea il client al tuo firmware
make clean
make -j PLATFORM=PM3RDV4 client # solo il client (piu' veloce)
```

La compilazione richiede qualche minuto.

---

## Passo 3 — Connettiti

Con il Proxmark3 collegato e la shell ProxSpace ancora aperta:

```bash
pm3 -p com7
```

(sostituisci `com7` con la tua porta). Al prompt `[usb] pm3 -->` sei connesso.
Verifica l'allineamento client/firmware:

```
hw version
```

Client e OS devono mostrare la stessa versione `v4.20469` → nessun `mismatch`.

---

## Passo 4 — Leggi la tessera T5577 (letture affidabili)

Con la tessera appoggiata sull'antenna LF:

```
lf t55xx detect
lf t55xx dump
lf search
lf search -u
```

Su USB diretta i dump sono affidabili: se la tessera contiene un ID reale, ora
lo vedrai correttamente (blocchi diversi tra loro, e/o un tag riconosciuto).

Comandi utili per il T5577:
```
lf t55xx read -b 1        # legge il blocco 1
lf t55xx read -b 2        # legge il blocco 2
lf t55xx info             # decodifica la configurazione
lf t55xx trace            # dati di tracciabilita' (pagina 1)
```

---

## Uso quotidiano senza comandi (doppio clic)

Dopo aver compilato il client una volta, per l'uso di tutti i giorni non serve
digitare nulla:

1. **Porta fissa** — in *Gestione dispositivi → Porte (COM e LPT)* → doppio clic
   sul *Dispositivo seriale USB* → *Impostazioni porta → Avanzate* → imposta un
   **Numero porta COM** stabile (es. COM3). Windows la userà sempre per questo device.
2. **Icona di avvio** — fai doppio clic su **`APRI-PROXMARK3.cmd`** (nella cartella
   del progetto): apre l'ambiente ProxSpace ed esegue `pm3` che **rileva la porta
   da solo** → ti ritrovi al prompt `[usb] pm3 -->` già connesso, senza comandi.

Se il doppio clic non si connette da solo (alcune versioni di ProxSpace non
accettano il comando passato), apri `C:\ProxSpace\runme64.bat` e scrivi una volta
`cd /pm3/proxmark3 && ./pm3`. Dimmelo e adatto l'icona alla tua versione.

---

## Tornare a WSL

Quando hai finito con Windows e vuoi riusarlo in Ubuntu:

```powershell
cd <cartella-del-progetto>\windows
./usa-in-wsl.ps1
```

Poi ricollega il device (o `usbipd attach --wsl --hardware-id 9ac4:4b8f`).

---

## Note

- Non tenere aperti contemporaneamente il client Windows e quello WSL sullo stesso
  device: uno solo alla volta può usare la porta.
- Se la build ProxSpace dà errori, verifica che il percorso sia senza spazi e
  rilancia `runme64.bat`.
