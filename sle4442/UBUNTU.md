# SLE4442 GUI su Ubuntu (Linux)

Istruzioni per usare il programma `sle4442_gui.py` (lettura e scrittura di
smart card SLE4442 con lettore ACS ACR39U) su **Ubuntu / Linux**.

Il programma e' lo stesso di Windows: e' Python multipiattaforma. Su Linux
cambia solo il sistema che gestisce le smart card, quindi vanno installati
alcuni pacchetti.

---

## 1. Installa i pacchetti necessari

```bash
sudo apt update
sudo apt install pcscd libccid python3-tk python3-pyscard pcsc-tools
```

Cosa sono:
- **pcscd** – il servizio smart card di Linux (come il servizio Smart Card
  di Windows).
- **libccid** – il driver per il lettore CCID (l'ACR39U).
- **python3-tk** – l'interfaccia grafica (Tkinter); su Ubuntu a volte non e'
  inclusa di default.
- **python3-pyscard** – la libreria PC/SC per Python (via apt, cosi' eviti
  problemi di compilazione).
- **pcsc-tools** – utilita' per verificare (`pcsc_scan`).

---

## 2. Avvia il servizio smart card

```bash
sudo systemctl enable --now pcscd
```

---

## 3. Verifica che il lettore sia visto

```bash
pcsc_scan
```

oppure:

```bash
python3 -c "from smartcard.System import readers; print(readers())"
```

Devi vedere l'**ACS ACR39U**. Premi Ctrl+C per uscire da `pcsc_scan`.

---

## 4. Avvia il programma

Spostati nella cartella dove hai messo `sle4442_gui.py` e lancia:

```bash
python3 sle4442_gui.py
```

Si apre la stessa finestra che hai su Windows:
- **Leggi carta** – legge i 256 byte, protezione e contatore PSC.
- **Salva .bin / Carica .bin** – backup e ripristino del dump.
- **Scrivi su carta** – clona il dump mostrato (presenta il PSC, poi verifica).
- **Azzera carta (FF)** – svuota una carta di cui conosci il PSC.
- Campo **PSC**: default `FFFFFF` (le carte vergini).

---

## 5. Se usi WSL (Ubuntu dentro Windows)

In WSL il lettore USB non si vede da solo. Devi:

1. agganciare l'ACR39U a WSL con **usbipd-win** (come per il Proxmark3):
   da PowerShell (amministratore) sul lato Windows:
   ```powershell
   usbipd list
   usbipd bind  --busid <BUSID-del-lettore>
   usbipd attach --wsl --busid <BUSID-del-lettore>
   ```
2. dentro WSL, far girare il servizio:
   ```bash
   sudo systemctl enable --now pcscd    # oppure: sudo pcscd --foreground --debug
   ```
3. poi verifica con `pcsc_scan` e avvia `python3 sle4442_gui.py`.

La grafica (Tkinter) funziona in WSL su Windows 11 grazie a WSLg.

Nota: su **Ubuntu nativo** (non WSL) e' tutto piu' semplice, perche' il
lettore USB e' visto direttamente.

---

## Note

- Un PSC errato in scrittura consuma un tentativo; dopo 3 errori la carta si
  blocca in scrittura per sempre. Il programma si ferma se il PSC e' errato.
- Se `pcsc_scan` non vede il lettore: controlla che `pcscd` sia attivo
  (`systemctl status pcscd`) e che il lettore sia collegato (`lsusb` deve
  mostrare "ACS ACR39U").
- Usa solo su carte tue o autorizzate.
