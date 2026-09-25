# Sintesi vocale con la tua voce (Coqui TTS + RVC)

Questa guida installa e usa [TTS-RVC-API](https://github.com/skshadan/TTS-RVC-API)
(la stessa descritta nella pagina Hugging Face *salamaniq*), dentro **Ubuntu su WSL2**.

## Come funziona

```
testo ──► Coqui TTS ──► voce "base" ──► RVC (tuo modello .pth + .index) ──► .wav con la TUA voce
```

- **Coqui TTS** trasforma il testo in parlato, ma addestrarlo sulla propria voce
  richiede tantissimi dati e tempo.
- **RVC** (Retrieval-based Voice Conversion) converte *voce in voce*: bastano 2-3
  minuti di registrazioni per addestrare un modello, perché parte da HuBERT
  (modello pre-addestrato).
- Unendoli: Coqui dà le parole, RVC dà il timbro.

> **Uso responsabile.** Clona solo la tua voce o quella di chi ti ha dato un
> consenso esplicito. Imitare la voce di altri per ingannare (truffe, finte
> telefonate, contenuti spacciati per autentici) è illegale.

---

## 1. Installazione (una volta sola)

**Da Windows:** doppio clic su `SINTESI-VOCALE.cmd`. La prima volta installa tutto,
poi avvia il server.

**Da Ubuntu/WSL:**

```bash
bash voce/setup-voce.sh
```

Cosa fa lo script:
- installa `ffmpeg`, gli strumenti di compilazione e **Python 3.10** (su Ubuntu 24.04
  lo prende dal PPA *deadsnakes*: `fairseq` e Coqui TTS non funzionano con Python ≥ 3.12);
- scarica TTS-RVC-API in `~/TTS-RVC-API` e crea l'ambiente `.venv`;
- installa le dipendenze e `TTS==0.22.0` (ultima versione di Coqui TTS);
- rende selezionabile il modello Coqui tramite la variabile `TTS_MODEL`
  (upstream usa un modello **solo inglese** fisso).

Servono diversi GB di spazio e parecchi minuti (PyTorch è grande). Senza GPU
NVIDIA funziona lo stesso, ma su CPU è più lento.

## 2. Aggiungi la tua voce RVC

Ti servono i due file di un modello **RVC v2** (addestrato ad es. con
*RVC WebUI* o *Applio*): il `.pth` e il `.index`.

```bash
bash voce/aggiungi-voce.sh mia_voce /mnt/c/Users/<tu>/Downloads/mia_voce.pth /mnt/c/Users/<tu>/Downloads/added_IVF256_mia_voce.index
```

Il risultato è la struttura richiesta dal server:

```
~/TTS-RVC-API/models/
└── mia_voce/
    ├── mia_voce.pth
    └── mia_voce.index
```

Ogni cartella deve contenere **esattamente un** `.pth` e **un** `.index`,
altrimenti il server non parte. Il repository include già tre voci di esempio
(`speaker1`, `speaker2`, `speaker3`, in inglese).

## 3. Avvia il server

```bash
bash voce/avvia-server.sh                                   # voce base italiana femminile
TTS_MODEL=tts_models/it/mai_male/vits bash voce/avvia-server.sh   # voce base italiana maschile
TTS_MODEL=tts_models/en/ljspeech/vits bash voce/avvia-server.sh   # originale inglese
```

Il server risponde su <http://localhost:8000> (pagina di prova interattiva:
<http://localhost:8000/docs>). Al primo avvio e alla prima richiesta scarica il
modello Coqui e HuBERT: attendi. Dopo aver aggiunto una voce, **riavvialo**.

## 4. Genera l'audio

In un secondo terminale (Ubuntu **o** Windows, basta Python 3):

```bash
python3 voce/genera-voce.py --elenco                        # voci disponibili
python3 voce/genera-voce.py -s mia_voce "Ciao! Benvenuto nel mondo."
python3 voce/genera-voce.py -s mia_voce -f testo.txt -o lettura.wav --speed 1.2
```

Oppure con una richiesta HTTP diretta:

```bash
curl -X POST http://localhost:8000/generate/ \
  -H 'Content-Type: application/json' \
  -d '{"speaker_name": "mia_voce", "input_text": "Ciao a tutti", "speed": 1.0}' \
  -o voce.wav
```

| Campo          | Obbligatorio | Note |
|----------------|--------------|------|
| `speaker_name` | sì           | nome della cartella in `models/` |
| `input_text`   | sì           | testo da pronunciare |
| `speed`        | no           | da 1.0 a 2.0 (default 1.0) |
| `emotion`      | no           | vedi sotto: con i modelli standard **non inviarlo** |

---

## Differenze rispetto alla pagina Hugging Face

La pagina originale è rimasta indietro rispetto al codice:

- **`config.toml` non esiste più**: i modelli vengono trovati da soli nella cartella
  `models/` (relativa alla directory da cui avvii il server; `avvia-server.sh` ci pensa).
- **`speaker_name` è obbligatorio**: se manca o è sbagliato risponde
  `400 speaker_name "..." was not found`.
- **`emotion` (happy, sad, angry, dull) non ha effetto** con i modelli VITS locali:
  era una funzione di *Coqui Studio*, servizio chiuso. Con Coqui TTS 0.22, inviare
  `emotion` insieme a `speed` (che il server imposta sempre) fa fallire la richiesta.
  Nell'esempio originale compare anche `"Surprise"`, che non è nell'elenco.
- **Lingua**: in origine la voce base è inglese (`ljspeech`). Qui di default è
  italiana; RVC cambia il timbro, non la lingua.
- **Endpoint**: usa `/generate/` con lo slash finale (senza, FastAPI risponde con
  un redirect).

## Problemi comuni

| Sintomo | Soluzione |
|---------|-----------|
| `Server non raggiungibile` | il server non è avviato: `bash voce/avvia-server.sh` |
| Il server si chiude subito con `MUST contain exactly 1 .index file` | in una cartella di `models/` ci sono più/nessun `.index`: sistemala o rilancia `aggiungi-voce.sh` |
| Errore durante `pip install` su `fairseq`/`pyworld` | assicurati che `.venv` usi Python 3.10: cancella `~/TTS-RVC-API/.venv` e rilancia `setup-voce.sh` |
| `ATTENZIONE: patch non applicata` | upstream ha cambiato il codice: resta la voce base inglese, il resto funziona |
| Molto lento | normale su CPU; con GPU NVIDIA in WSL serve il driver NVIDIA per WSL su Windows |
