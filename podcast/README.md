# Podcast AI — da un argomento a un episodio audio

Tu dai un argomento, io scrivo il copione, questo strumento lo trasforma in un
MP3 con voci neurali italiane.

```
argomento  ->  copione (.md)  ->  crea-podcast.py  ->  episodio.mp3
   tu            io                  le voci
```

Ascolta `esempi/esempio-rfid.md` per capire il risultato: due voci, due minuti,
un concetto spiegato.

---

## Come si usa

**Su Windows:** doppio clic su `CREA-PODCAST.cmd`, poi trascina dentro il copione.

**Da terminale (Ubuntu/WSL, macOS, Windows):**

```bash
pip install edge-tts                                  # una volta sola
python3 crea-podcast.py esempi/esempio-rfid.md        # crea esempio-rfid.mp3
python3 crea-podcast.py copione.md -o puntata-01.mp3  # nome file a scelta
python3 crea-podcast.py --voci                        # elenco voci disponibili
```

Non serve nessuna chiave e non si paga niente: le voci predefinite sono quelle
neurali di Microsoft Edge, gratuite.

---

## Il formato del copione

Un normale file di testo. In cima un blocco di impostazioni fra `---`, sotto le
battute, ognuna con davanti il nome di chi parla **in maiuscolo**.

```markdown
---
titolo: Cosa c'e' davvero dentro il tuo badge
voci:
  ANNA: it-IT-IsabellaNeural
  MARCO: it-IT-DiegoNeural
velocita: +4%
pausa_battute: 320
---

ANNA: Hai in tasca una tessera, e non ci pensi mai.
MARCO: E fin qui nessuno si fa domande.

[pausa 700]

ANNA(rate=-5%): Pero' dentro non c'e' nessuna batteria.
```

| Elemento | A cosa serve |
|---|---|
| `titolo:` | nome dell'episodio (compare nel riepilogo) |
| `voci:` | quale voce usa ogni personaggio |
| `velocita:` | ritmo generale, es. `+4%` (piu' svelto) o `-5%` (piu' calmo) |
| `tono:` | altezza della voce, es. `-2Hz` |
| `pausa_battute:` | respiro fra una battuta e l'altra, in millisecondi (350) |
| `[pausa 700]` | silenzio voluto: stacco fra due blocchi, effetto sospensione |
| `NOME(rate=-5%):` | rallenta o accelera **quella sola** battuta |
| righe che iniziano con `#` | commenti tuoi, non vengono lette |

Una battuta puo' andare a capo quante volte vuoi: le righe successive si
attaccano a quella sopra finche' non trovi una riga vuota.

Se in `voci:` non dichiari nessuno, i personaggi ricevono a turno una voce
femminile e una maschile.

### Voci italiane disponibili (gratuite)

| Voce | |
|---|---|
| `it-IT-IsabellaNeural` | femminile, calda, ottima per condurre |
| `it-IT-ElsaNeural` | femminile, piu' brillante |
| `it-IT-DiegoNeural` | maschile, tono da divulgazione |
| `it-IT-GiuseppeMultilingualNeural` | maschile, regge bene le parole straniere |

---

## Se vuoi il massimo realismo (ElevenLabs)

Le voci gratuite sono buone. Per la qualita' da podcast pubblicato si cambia
motore, tenendo lo **stesso identico copione**.

ElevenLabs e' un servizio esterno: ti dai un account e lui ti da' una *chiave*,
cioe' una lunga riga di caratteri che identifica te. Serve perche' le loro voci,
a differenza di quelle gratuite, sono legate a un account.

**Come si prende, una volta sola:**

1. Vai su [elevenlabs.io](https://elevenlabs.io) e crea un account — il piano
   gratuito basta per provare.
2. Clicca l'icona del profilo in alto a destra, poi **API keys**.
3. Copia la chiave e incollala dentro a un file di testo chiamato
   **`chiave-elevenlabs.txt`**, in questa stessa cartella.

Tutto qui. Il file resta sul tuo computer ed e' gia' escluso da Git, quindi non
finisce su GitHub. Da quel momento:

```bash
python3 crea-podcast.py copione.md -m elevenlabs
```

In Windows non devi nemmeno creare il file a mano: fai doppio clic su
`CREA-PODCAST.cmd`, scegli **[2] ElevenLabs**, incolla la chiave quando te la
chiede e la salva lui.

> Se preferisci la variabile d'ambiente classica (`ELEVENLABS_API_KEY`) funziona
> ancora e ha la precedenza sul file.

**Quali voci usare:** `python3 crea-podcast.py --voci -m elevenlabs` elenca quelle
del tuo account. Nel copione scrivi direttamente il nome, non l'ID:

```markdown
voci:
  ANNA: Sarah
  MARCO: Daniel
```

Scegli dalla libreria ElevenLabs voci *italiane*: il modello parla italiano con
qualunque voce, ma una voce nata in inglese si porta dietro un accento.

### OpenAI

Stessa logica, con `chiave-openai.txt` ([le chiavi si prendono
qui](https://platform.openai.com/api-keys)). Le voci si chiamano per nome
(`nova`, `onyx`, `shimmer`, `sage`...) e in piu' puoi dare la direzione d'attore:

```markdown
---
regia: Tono confidenziale, come se raccontassi un segreto a un amico.
voci:
  ANNA: nova
---
```

---

## Cosa fa funzionare un episodio

Qualche regola che uso quando scrivo i copioni:

- **Apri con una cosa concreta**, non con una definizione. "Hai in tasca una
  tessera" batte "L'RFID e' una tecnologia di identificazione".
- **Due voci che si parlano addosso** stancano meno di una che spiega da sola:
  chi ascolta si appoggia al dialogo.
- **Una sola idea per battuta.** Se una riga contiene due concetti, spezzala.
- **Le pause sono contenuto.** `[pausa 800]` prima di una rivelazione vale piu'
  di un aggettivo.
- **Chiudi con la frase che resta**, non con un riassunto.

Dieci minuti di episodio sono circa 1400 parole.

---

## Dettagli tecnici

Il montaggio e' fatto in puro Python: `crea-podcast.py` incolla i frame MP3 uno
dietro l'altro e costruisce i silenzi generando frame muti dello stesso formato
di quelli sintetizzati. Non serve `ffmpeg` e il risultato e' un MP3 regolare,
senza giunte sporche.

Le battute vengono sintetizzate quattro alla volta, con tre tentativi in caso di
problemi di rete, e poi rimesse in ordine.

Dietro a un proxy aziendale lo strumento legge da solo `HTTPS_PROXY`; se il
proxy termina il TLS, indica il certificato con `SSL_CERT_FILE`.
