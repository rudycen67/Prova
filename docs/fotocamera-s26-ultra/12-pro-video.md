# Capitolo 12 — Pro Video: il set di controlli completo

[← Capitolo 11](11-log-e-colore.md) · [Indice](README.md) · [Capitolo 13 →](13-stabilizzazione.md)

---

Se c'è una ragione tecnica per cui questo telefono finisce nelle mani di chi
gira video per lavoro, è questa modalità. Pro Video non è "la modalità Pro
applicata al video": è un set di controlli che copre tutto ciò che serve per
girare in modo ripetibile, e nella versione di quest'anno aggiunge due cose
che mancavano da anni.

---

## 12.1 Cosa sblocca Pro Video rispetto alla modalità Video

| | Video | Pro Video |
|---|---|---|
| ISO, tempo di posa, WB manuali | No | **Sì** |
| Fuoco manuale con peaking | No | **Sì** |
| Selezione esplicita dell'obiettivo | Parziale | **Sì** |
| Log | Sì | **Sì** |
| APV | Sì (4K60, 8K30) | **Sì, incluso 4K 120 fps** |
| Livelli audio e microfono | Limitato | **Completo** |
| Istogramma e strumenti di esposizione | No | **Sì** |
| Touch AF/AE durante la registrazione | — | **Sì** (novità) |
| Controller esterno TILTA | No | **Sì** (novità) |
| Mirroring 8K su schermo esterno | No | **Sì** (solo Ultra) |

Le ultime due righe sono le novità di questa generazione e meritano un
paragrafo ciascuna.

---

## 12.2 Touch AF/AE durante la registrazione

Finora, in Pro Video, una volta premuto REC eri bloccato: il fuoco e
l'esposizione erano quelli che avevi impostato, e per cambiarli dovevi fermare
la ripresa.

Adesso puoi **toccare lo schermo mentre registri** per spostare la messa a
fuoco e regolare la luminosità.

**Perché è importante:** rende possibili i *rack focus* — quei passaggi di
fuoco da un soggetto in primo piano a uno sullo sfondo che sono grammatica
cinematografica di base — senza attrezzature esterne. E ti permette di seguire
un soggetto che si sposta in profondità senza tagliare.

**Come farlo bene:**

- **tocca con decisione una volta sola.** Toccare ripetutamente produce un
  effetto "pompaggio" che si vede;
- **prova il passaggio prima di registrare**, per sapere quanto ci mette;
- se il cambio di esposizione è brusco, correggilo in montaggio con una
  dissolvenza: il fuoco è meccanico e naturale, il salto di luminosità no.

---

## 12.3 Il controller wireless TILTA

Pro Video supporta il **controller di obiettivo wireless TILTA**: un accessorio
fisico con una rotella che comanda la **messa a fuoco manuale** e fa partire e
fermare la **registrazione a distanza**.

**A chi serve:** a chi gira con il telefono su gimbal o su treppiede e ha
bisogno di mettere a fuoco senza toccare il dispositivo (toccare = far tremare),
o a chi lavora in due, con un operatore alla camera e uno al fuoco.

**A chi non serve:** a chiunque giri a mano libera. È un accessorio di un
ecosistema professionale, non un miglioramento generale.

Ne parlo perché è indicativo di dove Samsung sta portando questa modalità: da
"impostazioni avanzate" a **testa di ripresa integrabile in un set**.

---

## 12.4 I controlli, e i valori da cui partire

### Tempo di posa — bloccalo sempre

È la prima cosa da fare in Pro Video. Applica la regola dei 180°
(cap. [10](10-video-impostazioni.md)):

```
24 fps → 1/50 s      30 fps → 1/60 s
60 fps → 1/120 s    120 fps → 1/240 s
```

Lasciarlo in automatico significa che il telefono lo cambierà passando da una
zona di luce a un'altra, e il **mosso di movimento cambierà a metà ripresa**.
È uno degli scarti di qualità più visibili e meno riconosciuti.

### ISO — bloccalo anche lui

Se lo lasci automatico, il telefono lo farà salire e scendere durante la
ripresa e vedrai la luminosità **respirare**. Scegli un valore e tienilo:

| Situazione | ISO |
|---|---|
| Esterno soleggiato | 50–100 |
| Esterno nuvoloso, ombra | 100–200 |
| Interno luminoso | 400–800 |
| Interno serale, locale | 800–1600 |
| Notte in Log | non oltre 800, se puoi |

**Se non riesci a esporre correttamente con tempo e ISO bloccati**, non alzare
l'ISO oltre il ragionevole: aggiungi luce, cambia inquadratura, o accetta un
tempo di posa fuori regola. In pieno sole il problema è opposto (troppa luce) e
la soluzione è un **filtro ND**.

### Bilanciamento del bianco — in Kelvin, mai automatico

L'automatico durante una ripresa produce **slittamenti di colore** mentre
inquadri: una parete bianca entra nell'inquadratura e improvvisamente tutto
diventa più freddo. In montaggio è una correzione noiosissima.

Scegli un valore in Kelvin e non toccarlo per tutta la scena:

```
Esterno sole    5200–5500 K
Esterno nuvolo  6000–6500 K
Ombra           7000–7500 K
Interno caldo   2800–3200 K
Neon / ufficio  4000–4500 K
```

### Fuoco — manuale, con il peaking acceso

Attiva l'**evidenziazione del fuoco** (peaking): le zone a fuoco si colorano di
un contorno. È l'unico modo affidabile di verificare la messa a fuoco su uno
schermo da telefono, soprattutto in esterni con luce forte.

### Istogramma e zebre

Accendi l'**istogramma**. Su questa generazione hai anche le **zebre** (righe
diagonali sulle zone sovraesposte) e il **falso colore**, che colora l'immagine
per fasce di luminosità: sul campo sono ancora più immediate dell'istogramma.

**La regola per il video:** le luci bruciate in video sono **irrecuperabili** e
si notano molto più che in foto, perché il movimento le mette in evidenza. Nel
dubbio, mezzo stop più scuro.

---

## 12.5 L'audio: metà del video, e la parte che tutti dimenticano

Un video ben girato con audio pessimo è un video pessimo. L'inverso è meno
vero: uno spettatore perdona un'immagine mediocre, non un audio confuso.

### I controlli disponibili in Pro Video

- **Direzione del microfono**: omnidirezionale, solo anteriore (chi parla
  davanti al telefono), solo posteriore (il soggetto inquadrato). Sceglila in
  base a **chi deve essere sentito**.
- **Livelli di ingresso** con indicatore: puntali intorno a **−12 dB** nei
  momenti normali, così i picchi non arrivano a 0 e non distorcono. Un audio
  troppo basso si alza in montaggio; uno distorto non si recupera.
- **Microfono esterno**: USB-C e Bluetooth. Appena colleghi un microfono
  compatibile, l'app lo riconosce e puoi selezionarlo come sorgente.

### Le tre cose che migliorano l'audio più di qualsiasi impostazione

1. **Avvicina il microfono alla bocca.** Il rapporto fra suono utile e rumore
   ambientale peggiora col quadrato della distanza. Un microfono a 30 cm è
   incomparabilmente meglio di uno a 3 m, anche se è un microfono peggiore.
2. **Un radiomicrofono da bavero** costa poco e cambia categoria al risultato.
   È il miglior investimento possibile per chi fa vlog o interviste.
3. **Registra 10 secondi di silenzio ambientale** a ogni location. In montaggio
   servono per coprire i tagli e far sparire i buchi. È un trucco da
   professionisti che costa dieci secondi.

E una cosa da evitare: **il vento**. Anche una brezza leggera rovina l'audio in
modo irreparabile. Una cuffia antivento di gommapiuma sul microfono costa due
euro. Se non ce l'hai, riparati dietro qualcosa.

---

## 12.6 La checklist di Pro Video, da fare prima di ogni REC

```
□ Obiettivo scelto (e non lo cambio più)
□ Risoluzione e fps decisi
□ Tempo di posa = doppio degli fps, BLOCCATO
□ ISO scelto e BLOCCATO
□ WB in Kelvin, BLOCCATO
□ Fuoco verificato col peaking
□ Istogramma controllato: niente luci bruciate
□ Microfono selezionato, livelli intorno a −12 dB
□ Obiettivo PULITO
□ Spazio libero sufficiente (soprattutto in APV)
□ Non disturbare attivo (una notifica rovina la ripresa)
```

Trenta secondi. Ti risparmiano riprese inutilizzabili.

---

## Da ricordare

- In Pro Video **blocca tutto**: tempo, ISO e WB. L'automatico "respira" e si vede.
- **Touch AF/AE in ripresa** ti dà i rack focus senza attrezzatura.
- Il **peaking** è l'unico modo serio di verificare il fuoco su uno schermo piccolo.
- **Le luci bruciate in video non tornano.** Nel dubbio, più scuro.
- L'**audio** è metà del risultato: avvicina il microfono, punta a −12 dB,
  registra il silenzio d'ambiente.
- Usa la **checklist** prima di premere REC.

---

[← Capitolo 11](11-log-e-colore.md) · [Indice](README.md) · [Capitolo 13 →](13-stabilizzazione.md)
