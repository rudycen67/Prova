# Capitolo 16 — Workflow: esportazione, archiviazione, montaggio

[← Capitolo 15](15-editing.md) · [Indice](README.md) · [Capitolo 17 →](17-ricette.md)

---

Il modo più comune di rovinare una bella foto o un bel video non è sbagliare
un'impostazione: è **mandarlo a qualcuno**. Le app di messaggistica
ricomprimono senza chiedere, i cloud possono ridimensionare, e ciò che arriva
dall'altra parte ha una frazione dei dati che avevi.

Questo capitolo è breve e pratico: come far uscire i file dal telefono senza
danni, e come organizzarli in modo da ritrovarli fra due anni.

---

## 16.1 La tabella della perdita di qualità

| Metodo | Cosa succede |
|---|---|
| WhatsApp / Messenger — invio normale | **Compressione pesante.** Una foto da 5 MB arriva a 200 KB |
| WhatsApp — "documento" | **Nessuna compressione.** Il file arriva intero |
| Telegram — "invia senza compressione" | **Nessuna compressione** |
| Email | Nessuna compressione, ma limite di dimensione (~25 MB) |
| **Cavo USB-C verso PC** | **Nessuna perdita.** Il metodo migliore |
| Google Foto "qualità originale" | Nessuna perdita (consuma quota) |
| Google Foto "risparmio spazio" | **Ricompressione** |
| AirDrop / Quick Share | Nessuna perdita |
| Bluetooth | Nessuna perdita, ma lentissimo |

**Le due regole che risolvono tutto:**

1. Per condividere **al volo con qualcuno**, la compressione va benissimo:
   nessuno guarda una foto su WhatsApp con la lente.
2. Per **archiviare, stampare o montare**, usa il **cavo** o un invio senza
   compressione. Sempre.

E soprattutto: **non far passare un file attraverso due compressioni**. Una
foto scaricata da WhatsApp e rimandata via WhatsApp attraversa due cicli e
comincia a mostrare i blocchi.

---

## 16.2 Trasferire i video (dove la cosa si fa seria)

I file video di questo telefono sono **grandi**. Un 8K, o peggio un 4K in APV,
può occupare decine di gigabyte per pochi minuti di ripresa.

**Conseguenze pratiche:**

- **Usa un cavo USB-C dati**, non un cavo da ricarica economico. Molti cavi in
  circolazione trasportano solo corrente e non dati, e altri lo fanno a
  velocità USB 2.0, con cui trasferire 50 GB richiede un'ora.
- **Verifica lo spazio prima di girare**, non dopo. Rimanere senza memoria a
  metà di una ripresa in APV è un'esperienza che si fa una volta sola.
- **Un SSD esterno USB-C** collegato direttamente al telefono è la soluzione
  più pratica per chi gira molto: registri e scarichi sul posto.

---

## 16.3 Archiviare in modo da ritrovare le cose

Il problema non è dove mettere le foto, è **ritrovarle fra due anni**.

### La struttura minima che funziona

```
Foto/
  2026/
    2026-09-14 — Gita al lago/
      selezionate/      ← le 10 buone, sviluppate
      originali/        ← tutti gli scatti, RAW inclusi
    2026-09-20 — Compleanno Marta/
```

Tre regole:

1. **Data all'inizio, formato `AAAA-MM-GG`.** È l'unico formato che si ordina
   da solo in qualsiasi sistema.
2. **Una parola su cosa c'è dentro.** "IMG_20260914" non dice niente, "Gita al
   lago" sì.
3. **Separa le selezionate dagli originali.** Il valore di un archivio non sta
   nell'avere tutto: sta nel sapere quali sono le dieci che contano.

### La regola del 3-2-1

Per le cose a cui tieni davvero:

- **3** copie dei dati,
- su **2** supporti diversi (per esempio disco esterno + cloud),
- di cui **1** fuori casa.

Sembra eccessivo finché non si rompe un disco. Le foto sono l'unico file che
non puoi rifare.

---

## 16.4 Montare i video: cosa scegliere

| Programma | Piattaforma | Per chi |
|---|---|---|
| **DaVinci Resolve** | Win/Mac/Linux | **Gratuito e completo.** Il migliore per il colore e il Log |
| CapCut | Mobile / desktop | Veloce, orientato ai social |
| LumaFusion | Mobile (iPad/Android) | Montaggio serio da mobile |
| Premiere Pro | Win/Mac | Se già lo usi e hai l'abbonamento |
| Galleria Samsung | Telefono | Montaggi brevi, va benissimo |

**Per il materiale in Log o APV, DaVinci Resolve è la scelta giusta**, ed è
gratuito nella versione che ti serve. Il modulo di colore è quello che usano i
professionisti e gestisce nativamente il flusso di lavoro descritto nel
[capitolo 11](11-log-e-colore.md).

### Impostazioni di esportazione che vanno bene ovunque

```
Formato ........ MP4
Codec .......... H.264 (compatibilità) o H.265 (qualità/peso)
Risoluzione .... 1920×1080 o 3840×2160
Frame rate ..... lo STESSO della timeline, mai diverso
Bitrate ........ 1080p: 15–25 Mbps · 4K: 45–80 Mbps
Audio .......... AAC 256–320 kbps, 48 kHz
```

**L'errore più comune:** esportare a un frame rate diverso da quello della
timeline. Produce un micro-scatto ricorrente nel movimento che si vede e non si
capisce da dove venga. Timeline a 24? Esporta a 24.

---

## 16.5 Stampare

Una foto stampata è l'unico modo di guardarla davvero. E i file di questo
telefono reggono la stampa molto meglio di quanto si creda.

**Quanti pixel servono:**

| Formato | Pixel consigliati | Basta un… |
|---|---|---|
| 10×15 cm | ~1800×1200 | 12 MP abbondante |
| A4 | ~3500×2500 | 12 MP sufficiente |
| A3 | ~5000×3500 | 12 MP al limite, **50 MP comodo** |
| Poster 70×100 | ~8000×5500 | **200 MP** |

**Tre cose da fare prima di mandare in stampa:**

1. **Non affidarti allo schermo del telefono** per giudicare la luminosità: è
   molto più luminoso della carta. Le stampe vengono quasi sempre **più scure**
   del previsto. Schiarisci leggermente prima di inviare.
2. **Esporta in JPEG alla massima qualità**, non condividere via app.
3. **Controlla il ritaglio**: i formati di stampa hanno proporzioni diverse dal
   3:4 del sensore. Decidi tu cosa tagliare, prima che lo decida la tipografia.

---

## 16.6 La manutenzione che conta

**Spazio.** Controlla periodicamente cosa occupa la memoria: in genere sono i
video, la modalità Single Take e le copie RAW. Scarica e archivia con
regolarità invece di fare pulizie disperate quando il telefono si blocca.

**Temperatura.** Riprese lunghe in 8K o in 4K120, specialmente al sole, fanno
scaldare il dispositivo e a un certo punto le prestazioni vengono ridotte.
Se devi girare a lungo: togli la cover, tieni il telefono all'ombra fra una
ripresa e l'altra, non caricarlo mentre registri.

**Batteria.** Il video è l'attività che consuma di più in assoluto. Per una
giornata di riprese serve un power bank; e se giri con il telefono su un
treppiede, puoi alimentarlo mentre registra.

**L'obiettivo.** Vale la pena ripeterlo un'ultima volta: **puliscilo**. È
l'unica manutenzione che migliora ogni singola foto che farai.

---

## Da ricordare

- **WhatsApp comprime**: per archiviare usa il **cavo** o l'invio "come documento".
- Mai **due compressioni** sullo stesso file.
- Nomina le cartelle **`AAAA-MM-GG — descrizione`** e separa le selezionate.
- **3 copie, 2 supporti, 1 fuori casa.**
- **DaVinci Resolve** è gratuito ed è la scelta giusta per Log e APV.
- **Esporta allo stesso frame rate della timeline.**
- Le stampe vengono **più scure** dello schermo: schiarisci prima.

---

[← Capitolo 15](15-editing.md) · [Indice](README.md) · [Capitolo 17 →](17-ricette.md)
