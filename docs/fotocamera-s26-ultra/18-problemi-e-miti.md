# Capitolo 18 — Problemi comuni, limiti reali, miti da sfatare

[← Capitolo 17](17-ricette.md) · [Indice](README.md) · [Appendice A →](A-specifiche.md)

---

Ultimo capitolo, e il più onesto. Prima i problemi che incontrerai davvero con
la loro causa, poi i limiti fisici che nessun aggiornamento risolverà, poi le
cose che si leggono in giro e non sono vere.

---

## 18.1 Diagnostica: sintomo → causa → rimedio

### "Le foto vengono mosse"

| Se succede… | La causa è… | Rimedio |
|---|---|---|
| Di sera / in interno | Tempo di posa troppo lungo | Pro: SPEED 1/125 s, ISO più alto |
| Solo con soggetti che si muovono | L'OIS non congela il soggetto | Pro: SPEED 1/500 s |
| Solo a 5x/10x | Tremolio amplificato dalla focale | Appoggio, timer 2 s, raffica |
| Foto notturne specifiche | Ti sei mosso durante la cattura multi-frame | Resta fermo fino a fine conto alla rovescia |

### "Le foto sono rumorose / sgranate"

Quasi sempre è **poca luce**, non un difetto. Ma controlla anche:
- sei rimasto in **modalità Pro con ISO alto** da una sessione precedente?
- stai scattando a **200 MP** in condizioni che non lo permettono?
- stai usando il **tele 3x** in interno? Prova il 2x.
- l'**obiettivo è sporco**? Il velo riduce il contrasto e il telefono compensa.

### "Le foto sembrano finte / troppo elaborate"

- **Riduci la nitidezza** in Camera Assistant, se disponibile.
- Scatta con le **copie RAW** e sviluppale tu: eviti tutta l'elaborazione.
- Usa **Expert RAW**, che è meno aggressivo.
- Controlla di non aver lasciato attivo un filtro o il ritocco del ritratto.

### "Il colore cambia passando da un obiettivo all'altro"

È reale: sensori diversi, tarature diverse (cap. [11](11-log-e-colore.md) § 11.6).
Rimedio: blocca il WB in Kelvin in Pro/Pro Video e allinea in montaggio.

### "La messa a fuoco non aggancia"

- Sei **troppo vicino** per l'obiettivo in uso? Il principale si ferma a ~18 cm,
  il 5x a ~52 cm.
- Stai fotografando attraverso un **vetro o una rete**? Passa al fuoco manuale.
- Scena a **basso contrasto** o buio? Fuoco manuale, o punta su un bordo netto.
- Il soggetto si muove verso di te? Attiva **Traccia soggetto AF**.

### "Il telefono si scalda e il video si interrompe"

Riprese lunghe in 8K o 4K120 generano molto calore. Rimedi: togli la cover,
non caricare mentre registri, scendi a 4K 30, fai pause, tieni il telefono
all'ombra. Non è un guasto, è un limite termico.

### "Il video scatta / è a scatti"

- **Frame rate di esportazione diverso** da quello della timeline
  (cap. [16](16-workflow.md)).
- **Tempo di posa fuori dalla regola dei 180°**: 1/1000 s a 24 fps produce
  movimento scattoso.
- Panoramica troppo veloce: a 24 fps una panoramica rapida **strobo** sempre,
  anche nei film. Rallenta, o gira a 60 fps.

### "L'app fotocamera è lenta ad aprirsi"

In **Camera Assistant** c'è l'opzione per tenere la fotocamera in memoria e
aprirla istantaneamente. Attivala se perdi scatti mentre l'app carica.

---

## 18.2 I limiti reali, che nessun aggiornamento toglierà

Vale la pena conoscerli per non prendersela con il telefono.

**1. Il sensore è piccolo.** Grande per un telefono, quindici volte più piccolo
di un full-frame. Al buio con soggetti in movimento — la condizione peggiore in
assoluto — la differenza con una macchina vera è enorme e resterà tale.

**2. Il diaframma è fisso.** Non puoi chiudere per avere più profondità di
campo o per rallentare il tempo di posa in pieno sole. Per il video, l'unica
soluzione è un **filtro ND** fisico.

**3. Lo sfocato dei ritratti è calcolato.** Molto buono, ma sui bordi
complessi — capelli, occhiali, rami — si vede. Non è un bug da correggere:
è il limite di una stima di profondità fatta da un sensore piccolo.

**4. Il tele 3x è debole al buio.** 10 MP su 1/3.94": è una scelta progettuale.
In interni serali, il 2x ritagliato dal principale gli è superiore.

**5. Oltre il 30x l'immagine è ricostruita.** Utile per leggere, non per
fotografare.

**6. Super Steady costa qualità.** Più stabilizzazione = più ritaglio = meno
sensore. Non c'è pasto gratis.

**7. APV occupa moltissimo spazio.** È il prezzo del near-lossless.

**8. Il calore limita le riprese lunghe ad alta risoluzione.** Fisica, non
software.

---

## 18.3 Nove cose che si leggono in giro e non sono vere

**"Devi scattare sempre a 200 MP, altrimenti sprechi il telefono."**
Falso, e al contrario. A 12 MP ottieni **più** elaborazione multi-frame e in
quasi tutte le condizioni una foto migliore. I 200 MP servono in piena luce,
per ritagliare o per stampare grande. ([cap. 4](04-risoluzione.md))

**"La modalità Pro fa foto migliori."**
Falso. Fa foto **diverse**, con meno elaborazione. Serve in cinque situazioni
specifiche; fuori da quelle, l'automatico vince. ([cap. 6](06-modalita-pro.md))

**"Devi girare tutto in Log, è più professionale."**
Falso e dannoso. Un Log non colorato è **peggio** di un video standard, sempre.
Il Log è un mezzo per fare correzione colore, non un marchio di qualità.
([cap. 11](11-log-e-colore.md))

**"60 fps è meglio di 24 fps."**
Né meglio né peggio: **diverso**. 24 fps è il look cinematografico, 60 fps è il
look "diretta televisiva". La scelta è estetica, non tecnica.
([cap. 10](10-video-impostazioni.md))

**"Spegni l'ottimizzatore scena per avere colori veri."**
Consiglio sopravvalutato. Su questa generazione è calibrato bene, e spegnerlo
toglie anche elaborazione utile che non c'entra con la saturazione. Se i colori
non ti piacciono, correggili dopo. ([cap. 3](03-preparare-app.md))

**"L'OIS elimina il mosso."**
Falso a metà, ed è il malinteso più costoso. L'OIS corregge il **tuo**
tremolio. Un soggetto in movimento richiede un tempo di posa breve e l'OIS non
c'entra nulla. ([cap. 2](02-leggere-i-numeri.md))

**"f/1.4 sfoca lo sfondo come una reflex."**
Falso. La profondità di campo dipende anche dalla dimensione del sensore, che
qui è piccola: quasi tutto resta a fuoco. Lo sfocato dei ritratti è simulato.

**"Lo zoom 100x è uno zoom."**
Falso oltre il 10x circa. È ricostruzione algoritmica. Strumento di lettura,
non di fotografia. ([cap. 5](05-zoom.md))

**"Serve un gimbal per fare video decenti."**
Non più. Fra OIS, VDIS, Super Steady e Horizon Lock, il 90% delle esigenze è
coperto. Un gimbal resta utile per movimenti lenti e controllati e per il buio.
([cap. 13](13-stabilizzazione.md))

---

## 18.4 Le dieci cose da fare se ricordi solo una pagina di questo libro

1. **Pulisci l'obiettivo.** Ogni volta.
2. **Attiva la griglia** e tieni l'orizzonte dritto.
3. **Scatta a 12 MP** (o 24 con Camera Assistant), non a 200.
4. **Usa il 2x per le persone**, non l'1x da vicino.
5. **Sposta le persone all'ombra** quando c'è sole forte.
6. **Tieni premuto** per bloccare fuoco ed esposizione, poi ricomponi.
7. **Esponi per le luci:** una foto scura si recupera, un cielo bruciato no.
8. **Di notte, resta fermo** fino alla fine del conto alla rovescia.
9. **In video, blocca tempo, ISO e WB** e non cambiare obiettivo durante la ripresa.
10. **Cambia altezza.** Accucciati, sali, avvicinati. È gratis ed è quello che
    fa la differenza più grande di tutte.

---

## Coda

Questo telefono ha più capacità di quante ne userai. Va benissimo così: nessuno
usa tutto. Ma vale la pena sapere **cosa c'è**, perché il giorno in cui ti
serve un rallentatore a 120 fps, un RAW multi-frame o un orizzonte che resta
dritto mentre corri, la differenza fra averlo e saperlo usare è tutta lì.

E poi c'è la parte che nessun capitolo può darti: **uscire e fotografare**.
La fotocamera migliore resta quella che hai in tasca, e la tecnica migliore
resta quella che hai praticato abbastanza da non doverci più pensare.

---

[← Capitolo 17](17-ricette.md) · [Indice](README.md) · [Appendice A →](A-specifiche.md)
