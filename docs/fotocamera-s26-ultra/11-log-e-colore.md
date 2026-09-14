# Capitolo 11 — Log, APV e colore

[← Capitolo 10](10-video-impostazioni.md) · [Indice](README.md) · [Capitolo 12 →](12-pro-video.md)

---

Il Log è la funzione che più spesso viene attivata per sbaglio e più spesso
rovina i video di chi non sa cosa sta facendo. Questo capitolo serve a
metterti dalla parte giusta: **usare il Log quando serve, e non usarlo mai
per abitudine**.

---

## 11.1 Cos'è il Log, in una pagina

Un sensore vede una gamma di luminosità molto più ampia di quella che un file
video standard può contenere. Quando registri in modalità normale, il telefono
**decide per te** come comprimere quella gamma: alza il contrasto, satura i
colori, taglia le ombre più scure e le luci più chiare, e ti consegna un file
già "bello" — e già irreversibile.

Il **Log** fa l'opposto. Registra una curva logaritmica che conserva il più
possibile agli estremi, e il file che ne esce è **piatto, grigiastro,
desaturato**. Sembra rotto. Non lo è: contiene molte più informazioni di quello
bello.

```
VIDEO STANDARD          VIDEO LOG
contrasto alto          contrasto piatto
colori decisi           colori spenti
ombre chiuse            ombre aperte e recuperabili
luci tagliate           luci conservate
pronto all'uso          DA COLORARE, obbligatoriamente
```

**La regola assoluta:** se non hai intenzione di fare correzione colore in
montaggio, **non girare in Log**. Un Log non colorato è peggio di qualsiasi
video normale, sempre, senza eccezioni.

---

## 11.2 Quando il Log vale davvero la pena

Tre situazioni, molto concrete:

**1. Contrasto estremo nella scena.** Un interno con una finestra luminosa, un
soggetto in ombra sotto un cielo bianco, un tramonto con primo piano scuro. In
standard perdi da una parte o dall'altra; in Log tieni entrambe e decidi dopo.

**2. Riprese fatte in momenti o luoghi diversi che devono stare insieme.** Se
giri una scena al mattino e una al pomeriggio, in Log puoi farle combaciare in
correzione colore. In standard hanno due caratteri che non si allineano.

**3. Vuoi un look preciso.** Un'estetica fredda, un'aria da pellicola, un
viraggio: partendo dal Log puoi costruirla. Partendo da un file già contrastato
puoi solo peggiorarla.

**Fuori da questi tre casi, il video standard è la scelta migliore** — e non è
un ripiego: il profilo standard di Samsung è calibrato molto bene.

---

## 11.3 Come girare in Log senza rovinare tutto

### Esponi più chiaro del solito

Il Log ha bisogno di luce. Le ombre di un Log sottoesposto contengono rumore
che salta fuori appena lo tiri su in correzione colore. **Esponi da mezzo stop
a uno stop sopra** quello che ti sembra corretto — l'immagine ti sembrerà
slavata sul mirino, ed è giusto così.

La regola pratica: sull'istogramma, il grosso dell'immagine deve stare
**verso destra**, senza toccare il bordo.

### Tieni l'ISO basso

Il rumore in Log è molto più evidente che in standard, perché la correzione
colore lo amplifica. Sotto ISO 800 quando puoi.

### Usa una LUT di anteprima, se c'è

Alcune modalità offrono di **visualizzare** l'immagine con un profilo corretto
pur **registrando** in Log. Se la trovi, attivala: comporre e giudicare
l'esposizione guardando un'immagine grigia è molto difficile.

### Non mescolare

Tutte le riprese di un progetto in Log, o tutte in standard. Metà e metà è la
strada più veloce per un montaggio che sembra assemblato da due persone diverse.

---

## 11.4 Log + APV: la combinazione seria

Il Log conserva informazione nelle **gradazioni**. Un codec che comprime
aggressivamente butta via proprio quelle gradazioni. Il risultato sono le
**banding** — le strisce visibili nei cieli e nelle sfumature — che compaiono
non appena spingi il contrasto in correzione.

Ecco perché **Log e APV sono fatti l'uno per l'altro**: APV è near-lossless e a
10/12 bit, quindi le gradazioni sopravvivono al viaggio.

La combinazione che l'S26 Ultra permette e che nessun altro telefono offre
oggi:

```
4K · 120 fps · APV · Log     ← solo in modalità PRO VIDEO
4K ·  60 fps · APV · Log     ← disponibile anche in modalità Video normale
8K ·  30 fps · APV · Log     ← disponibile anche in modalità Video normale
```

**Attenzione allo spazio.** Un minuto di 4K120 in APV occupa molti gigabyte.
Prima di una giornata di riprese, svuota la memoria e sappi quanto ti resta.
Controlla anche che la scheda o il dispositivo su cui trasferirai regga il
flusso di dati.

---

## 11.5 Colorare il Log: il flusso minimo che funziona

Non serve essere coloristi. Servono quattro passaggi, in quest'ordine.

### Passo 1 — Applica una LUT di conversione

Una **LUT** (*Look-Up Table*) è una tabella che traduce i colori piatti del Log
in colori normali. Cercane una per il profilo Log di Samsung, oppure usa la
conversione integrata nel tuo programma di montaggio. Questo passaggio non è
creativo: è **tecnico**, riporta l'immagine alla normalità.

### Passo 2 — Sistema l'esposizione e i punti estremi

- porta i **neri** fino a toccare il nero vero (senza schiacciarli);
- porta i **bianchi** fino quasi al bianco (senza bruciare);
- aggiusta la **luminosità media** al gusto.

Un'immagine senza nero vero sembra sempre sporca e sbiadita. Questo è il
passaggio che il 90% delle persone salta ed è il 90% del risultato.

### Passo 3 — Bilancia il bianco

Guarda una zona che dovrebbe essere **grigia o bianca** (un muro, una camicia,
un foglio) e correggi finché non lo è davvero. Solo dopo aver fatto questo puoi
giudicare il resto.

### Passo 4 — Il look

Adesso puoi divertirti: viraggi, saturazione, curve. Sempre **meno di quanto
ti verrebbe** — la correzione colore invecchia male e i look aggressivi
invecchiano prima degli altri.

**Programmi consigliati:** DaVinci Resolve (gratuito, e la versione gratuita
è completa per questo lavoro), CapCut o LumaFusion su mobile, Premiere Pro se
già lo usi.

---

## 11.6 Coerenza del colore fra i quattro obiettivi

Un problema reale e poco discusso: i quattro obiettivi hanno sensori di
generazioni e marche diverse (Samsung ISOCELL e Sony), e i loro colori **non
sono identici**. Un taglio da 1x a 5x nello stesso montaggio si vede: cambia
leggermente la tinta, il contrasto, il rumore.

**Tre contromisure:**

1. **Gira tutta una scena con lo stesso obiettivo**, se puoi.
2. **Blocca il bilanciamento del bianco in Kelvin** in Pro Video, uguale per
   tutte le riprese della scena. L'automatico è la prima causa di scarti di
   colore.
3. In montaggio, **allinea le riprese a quella che ti piace di più** con una
   correzione per clip, prima di applicare il look generale.

---

## Da ricordare

- Il **Log** è un negativo, non un'immagine finita: **va colorato, sempre**.
- Se non fai correzione colore, il **profilo standard è migliore**. Senza sensi di colpa.
- In Log: **esponi più chiaro** e tieni l'**ISO basso**.
- **Log + APV** è la combinazione che evita il banding — e mangia gigabyte.
- Colorare: **LUT → punti estremi → bilanciamento bianco → look**, in quest'ordine.
- Blocca il **WB in Kelvin** per tenere insieme riprese e obiettivi diversi.

---

[← Capitolo 10](10-video-impostazioni.md) · [Indice](README.md) · [Capitolo 12 →](12-pro-video.md)
