# Capitolo 7 — Expert RAW, astrofotografia e Virtual Reflector

[← Capitolo 6](06-modalita-pro.md) · [Indice](README.md) · [Capitolo 8 →](08-ritratto-macro-notte.md)

---

Expert RAW è un'app **separata**, gratuita, da scaricare dal Galaxy Store. Non
è preinstallata, e questo è il motivo per cui la maggior parte delle persone
non sa che esiste.

È anche il pezzo di software che più avvicina questo telefono a una macchina
fotografica vera: perché a differenza della modalità Pro, **non rinuncia alla
fusione multi-frame**. Ti dà il controllo manuale *e* l'elaborazione
computazionale insieme, e ti consegna un RAW a 16 bit che è già il risultato
di una decina di scatti fusi.

---

## 7.1 Perché Expert RAW batte la modalità Pro

| | Modalità Pro | Expert RAW |
|---|---|---|
| Controllo manuale completo | Sì | Sì |
| RAW | `.dng` singolo scatto | **`.dng` multi-frame a 16 bit** |
| Fusione HDR | Molto limitata | **Sì, completa** |
| Gamma dinamica recuperabile | Buona | **Molto superiore** |
| Rumore nelle ombre | Visibile | **Molto ridotto** |
| Astrofotografia | No | **Sì, dedicata** |
| Velocità di scatto | Immediata | Lenta (1–3 s di elaborazione) |

La riga che decide è la terza. Un `.dng` di Expert RAW contiene le informazioni
di più esposizioni fuse: puoi tirare su le ombre di tre stop e trovarci
dettaglio pulito, cosa che con un RAW singolo non succede.

**Il prezzo è il tempo.** Dopo lo scatto l'app impiega qualche secondo a
elaborare. Non è un'app per soggetti veloci. È un'app per paesaggi, architettura,
ritratti posati, interni, notte.

---

## 7.2 Come si usa, in pratica

All'apertura trovi una barra di controlli simile alla modalità Pro (ISO, tempo,
WB, fuoco manuale, obiettivo) più alcune cose in più.

**Le tre impostazioni da sistemare la prima volta:**

1. **Formato di salvataggio.** Puoi salvare solo `.dng`, solo `.jpg`, o
   entrambi. Scegli **entrambi**: il JPEG ti serve per guardare e condividere
   subito, il DNG per lavorare.
2. **Risoluzione.** Expert RAW offre anche una modalità a **50 MP**. Per
   paesaggi in piena luce ha senso; per tutto il resto, 12 MP.
3. **Obiettivo esplicito.** Come in Pro, qui scegli tu l'ottica e il telefono
   non ti scavalca.

**Il flusso di lavoro tipico:**

```
1. Inquadra e componi con calma (non è un'app da scatto rapido)
2. Tocca per mettere a fuoco, verifica con l'istogramma
3. Appoggia il telefono o usa un treppiede se il tempo è lungo
4. Scatta e ASPETTA l'elaborazione senza muoverti
5. Sviluppa il .dng in Lightroom / Snapseed / Darktable
```

---

## 7.3 Virtual Reflector: la novità di questa generazione

È la funzione nuova di Expert RAW su questa serie, e vale da sola il download.

**Cosa fa:** simula un **pannello riflettente**, l'attrezzo che i fotografi
usano per rimbalzare la luce nelle ombre di un volto. Invece di schiarire tutta
l'immagine (che appiattisce), riconosce il soggetto e apre selettivamente le
ombre come farebbe una luce di rimbalzo reale.

**Dove funziona meglio:** sui **volti**, e in particolare in controluce — la
situazione classica in cui il viso viene nero contro un cielo luminoso.

**Come si usa:** hai un'**anteprima dal vivo**, quindi puoi regolare l'intensità
guardando il risultato prima di scattare. Questa è la parte importante: non è
un filtro applicato dopo, è una decisione presa durante lo scatto, e il
risultato finisce dentro il file.

**Il consiglio:** tienilo **basso**. L'effetto a intensità piena si riconosce
subito e sa di finto. Usalo per recuperare due stop di ombra sul viso, non per
trasformare il controluce in luce frontale.

---

## 7.4 Astrofotografia

Nell'elenco delle modalità di Expert RAW c'è l'astrofotografia. È una posa
lunghissima assistita: il telefono cattura per diversi minuti, somma i
fotogrammi, compensa la rotazione delle stelle e sovrappone (se vuoi) una mappa
delle costellazioni.

**I quattro requisiti non negoziabili:**

1. **Un treppiede.** Non "un appoggio". Un treppiede. La posa dura minuti.
2. **Cielo veramente buio.** Dalla periferia di una città non funziona:
   l'inquinamento luminoso satura tutto di arancione dopo pochi secondi.
3. **Nessuna luna** (o luna molto calante). La luna piena illumina il cielo
   come un lampione.
4. **Pazienza.** Dalla preparazione alla foto finale passano dai cinque ai
   quindici minuti.

**La procedura:**

```
1. Treppiede stabile, telefono in verticale o orizzontale secondo la composizione
2. Expert RAW → modalità astrofotografia
3. Metti a fuoco MANUALMENTE all'infinito (non lasciarlo all'autofocus:
   al buio non aggancia niente)
4. Imposta la durata (più lunga = più stelle, ma anche più scie)
5. Avvia e NON TOCCARE il telefono fino alla fine
```

**Il trucco compositivo che fa la differenza:** un cielo stellato da solo è
noioso. Metti in inquadratura **qualcosa di terrestre** — un albero isolato, un
rudere, una cresta di montagna, una persona con una torcia. La scala rende
l'immagine.

**Un'avvertenza sull'inquadratura:** la Via Lattea è visibile e fotografabile
nell'emisfero nord soprattutto **da aprile a settembre**, e il centro galattico
(la parte spettacolare) si trova verso **sud**. Un'app di planetario ti dice
dove guardare e a che ora.

---

## 7.5 E la luna?

L'astrofotografia serve per il cielo profondo, non per la luna. La luna è
**luminosissima**: esposta come le stelle diventa un disco bianco.

Per fotografare la luna con dettaglio:

```
Modalità Pro (non astrofotografia)
Obiettivo 5x, zoom fino a 10x
ISO 50–100 · SPEED 1/125 – 1/250 s · WB 5500 K
Fuoco manuale all'infinito · Treppiede o appoggio solido
```

Sì: la luna in pieno giorno di esposizione si comporta come una scena
soleggiata, perché *è* una roccia illuminata dal sole. È la cosiddetta
"regola f/11": tempi brevi, ISO bassi. Se la tua luna viene una palla bianca,
non stai sbagliando fuoco — stai sovraesponendo di sei stop.

---

## 7.6 Sviluppare il `.dng`: il minimo indispensabile

Un RAW non sviluppato è peggio del JPEG. Ecco i cinque cursori che bastano per
il 90% dei casi, nell'ordine giusto:

1. **Esposizione** — porta l'immagine alla luminosità giusta nel complesso.
2. **Luci (Highlights) giù / Ombre (Shadows) su** — recupera i due estremi.
   Qui si vede il vantaggio del multi-frame di Expert RAW.
3. **Bianchi e Neri** — imposta i due punti estremi. I neri *devono* toccare
   il nero: un'immagine senza nero vero sembra sbiadita.
4. **Bilanciamento del bianco** — qui è gratis, usalo per dare atmosfera.
5. **Texture / Chiarezza** — piccole dosi. La nitidezza esagerata è la firma
   dell'amatore.

**App consigliate:** Lightroom Mobile (gratuita nelle funzioni base, legge i DNG
di Samsung perfettamente), Snapseed (gratuito, ottimo il "Correzione selettiva"),
Darktable o RawTherapee su desktop se preferisci il software libero.

---

## Da ricordare

- Expert RAW è **un'app separata da scaricare**: senza, ti perdi il meglio.
- Il suo `.dng` è **multi-frame a 16 bit**: molto più recuperabile di un RAW normale.
- **Virtual Reflector** salva i volti in controluce — ma tienilo basso.
- L'**astrofotografia** richiede treppiede, cielo scuro, niente luna e pazienza.
- La **luna** si fotografa in Pro con tempi brevi, non in astrofotografia.
- Un RAW **va sviluppato**, altrimenti è inferiore al JPEG automatico.

---

[← Capitolo 6](06-modalita-pro.md) · [Indice](README.md) · [Capitolo 8 →](08-ritratto-macro-notte.md)
