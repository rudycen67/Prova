# Podcast AI — da un argomento a un episodio audio

Tu dai un argomento, io scrivo il copione, questo strumento lo trasforma in un
MP3 con voci neurali italiane.

```
argomento  ->  copione (.md)  ->  crea-podcast.py  ->  episodio.mp3
   tu            io                  le voci
```

Nella cartella `esempi/` ci sono i due formati che funzionano meglio:

| Esempio | Formato | Quando usarlo |
|---|---|---|
| `esempio-rfid.md` | **dialogo** a due voci | spiegare come funziona qualcosa: chi ascolta si appoggia al botta e risposta |
| `esempio-monologo.md` | **monologo** a una voce | raccontare una storia o una vita: e' il formato di *Founders*, ritmo serrato e frasi corte |

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
| `voci_google:` | le voci da usare **solo** con `-m google` (stessa cosa per `voci_elevenlabs:` e `voci_openai:`), cosi' lo stesso copione gira su tutti i motori |
| `regia:` | come deve suonare, detto a parole — vale per `google` e `openai` |
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

## Voci piu' espressive: Google, ElevenLabs, OpenAI

Le voci gratuite sono buone ma **cordiali per costruzione**: qualunque cosa
scrivi, te la leggono con la stessa gentilezza. Se ti serve intensita' — un
monologo che incalza, un tono confidenziale — serve un motore che accetti la
*regia*, cioe' la direzione d'attore.

Il copione resta identico: cambia solo il motore.

| Motore | Costo | Cosa ti da' in piu' |
|---|---|---|
| **google** | chiave gratuita | il tono si dirige **a parole**; 30 voci |
| **elevenlabs** | account, piano gratuito per provare | le voci piu' realistiche in assoluto |
| **openai** | a consumo | regia recitativa, buona resa |

### Google (consigliato per iniziare)

1. Vai su [aistudio.google.com/apikey](https://aistudio.google.com/apikey) e
   accedi col tuo account Google.
2. Clicca **Create API key** e copia la chiave.
3. Incollala in un file **`chiave-google.txt`** in questa cartella.

```bash
python3 crea-podcast.py copione.md -m google
python3 crea-podcast.py --voci -m google        # le 30 voci e il loro carattere
```

La differenza vera e' la riga `regia:` nell'intestazione del copione: descrivi
a parole come vuoi che suoni, e la voce ti segue.

```markdown
---
regia: Leggi come un narratore appassionato che sta convincendo un amico a cambiare vita, ritmo incalzante, abbassando la voce sulle frasi che pesano
voci:
  VOCE: Algenib
---
```

Puoi anche dare indicazioni dentro al testo, fra parentesi quadre:
`[sussurrando]`, `[lentamente]`, `[con entusiasmo]`.

Voci adatte a un monologo: **Algenib** (roca), **Sadaltager** (competente),
**Gacrux** (matura), **Charon** (informativa). Per il dialogo: **Sulafat**
(calda), **Achird** (amichevole), **Zubenelgenubi** (informale).

> Con Google l'episodio esce in **WAV** invece che MP3: le loro voci
> restituiscono audio grezzo, non compresso. Si ascolta ovunque, pesa di piu'.
> Anche `velocita:` e `tono:` non valgono qui — il ritmo si chiede nella `regia:`.

### ElevenLabs

Account su [elevenlabs.io](https://elevenlabs.io), icona del profilo in alto a
destra, **API keys**, e la chiave va in **`chiave-elevenlabs.txt`**.

```bash
python3 crea-podcast.py copione.md -m elevenlabs
python3 crea-podcast.py --voci -m elevenlabs     # le voci del tuo account
```

Nel copione scrivi il nome della voce, non l'ID: `ANNA: Sarah`. Scegli dalla
libreria voci *italiane* — il modello parla italiano con qualunque voce, ma una
voce nata in inglese si porta dietro l'accento.

### OpenAI

Chiave da [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
in **`chiave-openai.txt`**. Le voci si chiamano per nome (`nova`, `onyx`,
`shimmer`, `sage`...) e vale la stessa riga `regia:`.

### Dove mettere la chiave: tre modi

| Modo | Come | Quando conviene |
|---|---|---|
| **File** | `chiave-google.txt` in questa cartella | uso normale sul tuo computer; in Windows te lo crea il `.cmd` |
| **Variabile d'ambiente** | `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`, `OPENAI_API_KEY` | ha la precedenza sul file |
| **Credenziale dell'ambiente** | registrata una volta sull'ambiente cloud, poi `--chiave-esterna` | quando lavori con Claude nel cloud e **non vuoi che la chiave entri nella sessione** |

Il terzo modo merita una spiegazione. Sui piani Pro e Max si puo' registrare una
chiave sull'ambiente cloud: a quel punto e' il proxy di Anthropic ad aggiungerla
alle richieste *dopo* che escono dalla macchina della sessione. La chiave non
arriva mai a Claude, ne' ai comandi che esegue, ne' alle variabili d'ambiente.

Si registra da [claude.ai/code](https://claude.ai/code), aprendo l'ambiente in
modifica: **API credentials** sotto **Environment variables**, poi
**Add credential**. Per Gemini:

- **Allowed websites**: `generativelanguage.googleapis.com`
- **Custom headers**: nome `x-goog-api-key`, **prefisso vuoto**, valore = la chiave

Poi lo strumento va lanciato cosi', perche' non provi a cercare una chiave che
non vedra' mai e non mandi un'intestazione doppia:

```bash
python3 crea-podcast.py copione.md -m google --chiave-esterna
```

> I file delle chiavi restano sul tuo computer e sono esclusi da Git.

## Cosa fa funzionare un episodio

Qualche regola che uso quando scrivo i copioni:

- **Apri con una cosa concreta**, non con una definizione. "Dieci posti, un
  bancone, sotto una stazione della metropolitana" batte "Jiro Ono e' un noto
  cuoco giapponese".
- **Una sola idea per battuta.** Se una riga contiene due concetti, spezzala.
  E' anche il motivo per cui le frasi corte suonano meglio: la voce prende fiato
  dove finisce la riga.
- **Le pause sono contenuto.** `[pausa 800]` prima di una rivelazione vale piu'
  di un aggettivo.
- **Chiudi con la frase che resta**, non con un riassunto.

Nel **monologo** in piu': rallenta le frasi che devono pesare
(`VOCE(rate=-5%):`), ripeti la frase chiave da sola su una riga, e parla a
*te*, non a "voi". Nel **dialogo**: chi fa le domande non deve essere finto,
deve dire quello che penserebbe chi ascolta.

I numeri scritti in cifre vengono letti male: nei copioni scrivo
`millenovecentosessantacinque`, non `1965`.

Dieci minuti di episodio sono circa 1400 parole. Il monologo d'esempio, 3400
caratteri, dura quattro minuti.

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
