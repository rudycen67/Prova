# Capitolo 6 — Modalità Pro: esposizione manuale e RAW

[← Capitolo 5](05-zoom.md) · [Indice](README.md) · [Capitolo 7 →](07-expert-raw.md)

---

Prima di tutto, una verità che nessun tutorial dice: **la modalità Pro non fa
foto più belle dell'automatico.** Fa foto *diverse*. Rinuncia a gran parte
della fusione multi-frame e della magia computazionale in cambio di controllo
totale.

Quindi il modo giusto di pensarla è: la modalità Pro non è il "livello
avanzato" della modalità Foto. È **uno strumento per casi in cui l'automatico
sbaglia** — e sono meno di quanto pensi, ma quando capitano, sono decisivi.

---

## 6.1 I cinque casi in cui la Pro vince davvero

1. **Soggetto in movimento in poca luce.** L'automatico allunga il tempo di
   posa per raccogliere luce e ti restituisce una scia. In Pro imposti
   1/250 s e accetti il rumore: una foto rumorosa esiste, una mossa no.
2. **Esposizione lunga voluta.** Scie di auto, acqua setosa, fuochi
   d'artificio, luci di una giostra. Serve un tempo lungo *deciso da te*.
3. **Scene che ingannano l'esposimetro.** Neve, spiaggia, controluce, un
   teatro con un faro su fondo nero. L'automatico media e sbaglia.
4. **Coerenza fra scatti.** Se fotografi venti oggetti per un catalogo, o fai
   un panorama da unire, ti serve che tutti gli scatti abbiano stessa
   esposizione e stesso bilanciamento del bianco. In automatico variano.
5. **Quando vuoi il RAW.** Le copie `.dng` si ottengono qui.

Fuori da questi casi, torna in Foto: vincerà lui.

---

## 6.2 I controlli, uno per uno

La barra in basso in modalità Pro contiene, da sinistra:

### ISO — la sensibilità

`ISO 50` … `ISO 3200` (o oltre)

Quanto il sensore amplifica il segnale. Più alto = immagine più luminosa e
**più rumorosa**.

| ISO | Quando |
|---|---|
| 50–100 | Piena luce, treppiede, massima qualità |
| 200–400 | Interni ben illuminati, ombra all'aperto |
| 800–1600 | Sera, interni normali |
| 3200+ | Emergenza: meglio rumoroso che mosso |

**Regola:** tieni l'ISO **il più basso possibile compatibilmente con un tempo
di posa che non ti dia mosso.** Il tempo viene prima, l'ISO si adatta.

### SPEED — il tempo di posa

Da circa `1/12000 s` a `30 s`.

| Tempo | A cosa serve |
|---|---|
| 1/1000 s+ | Sport, uccelli, spruzzi d'acqua congelati |
| 1/250 s | Persone che camminano, bambini, animali |
| 1/125 s | Ritratto di qualcuno che sta abbastanza fermo |
| 1/60 s | Minimo per soggetti fermi a mano libera a 1x |
| 1/15 – 1/4 s | Solo con appoggio; effetto mosso voluto |
| 1 – 30 s | **Solo treppiede.** Scie, acqua, notte, stelle |

**La regola del reciproco, versione telefono:** a mano libera non scendere sotto
`1 / (focale equivalente)`. Cioè circa **1/30 s a 1x**, **1/60 s a 2x**,
**1/125 s a 5x**, **1/250 s a 10x**. L'OIS ti regala due o tre stop di margine
su queste soglie, ma solo per il *tuo* tremolio.

### EV — la compensazione dell'esposizione

Utile quando lasci ISO e tempo in automatico e vuoi solo dire al telefono
"più chiaro" o "più scuro".

- **Neve, spiaggia, nebbia, sfondo bianco:** +0.7 / +1.3 EV, altrimenti il grigio.
- **Controluce, teatro, concerto, fuoco su fondo nero:** −0.7 / −1.7 EV,
  per non bruciare le luci.

### FOCUS — la messa a fuoco manuale

Un cursore da un'icona di fiore (vicino) a una di montagna (infinito). Serve in
tre casi: attraverso un vetro o una rete (l'autofocus aggancia il vetro), al
buio totale (l'autofocus non trova contrasto) e per le stelle (porti a fondo
scala verso l'infinito e arretri di un pelo).

Attivando il **peaking** (evidenziazione del contrasto) le zone a fuoco si
colorano: è il modo più affidabile di verificare a occhio.

### WB — il bilanciamento del bianco

In Kelvin, da ~2300 K a ~10000 K.

| Kelvin | Luce |
|---|---|
| 2700–3000 K | Lampadina calda, interni domestici |
| 4000 K | Neon, luce mista |
| 5200–5500 K | Luce del sole a mezzogiorno |
| 6500 K | Cielo coperto |
| 7500–9000 K | Ombra in giornata limpida, ora blu |

**Il trucco creativo:** imposta un valore *più alto* del reale e l'immagine si
scalda (tramonti più intensi); *più basso* e si raffredda (notti più blu,
atmosfera fredda). È la leva più espressiva della modalità Pro e quasi nessuno
la tocca.

### Obiettivo

In Pro scegli **esplicitamente** l'obiettivo, e il telefono non ti scavalca
(vedi [cap. 5](05-zoom.md) § 5.5). È uno dei motivi migliori per usare la Pro
anche in situazioni semplici.

---

## 6.3 L'istogramma: l'unico strumento che non mente

Attiva l'**istogramma** dalle impostazioni della modalità Pro. È un grafico
della distribuzione della luce: a sinistra i neri, a destra i bianchi.

```
 nero ▏▂▃▅▇█▇▅▃▂▏ bianco
      └── se il grafico è schiacciato a destra
          e "tocca" il bordo, stai bruciando le luci:
          quel dettaglio è perso per sempre
```

**Come leggerlo in tre secondi:**

- **Ammassato a sinistra** → foto sottoesposta. Ma le ombre si recuperano
  abbastanza bene, soprattutto in RAW.
- **Ammassato a destra e attaccato al bordo** → luci bruciate. **Non si
  recuperano.** Scendi di esposizione.
- **Distribuito senza toccare i bordi** → hai il massimo delle informazioni.

**La regola d'oro del digitale:** nel dubbio, **esponi per le luci**. Meglio una
foto un po' scura da schiarire che un cielo bianco irrecuperabile.

---

## 6.4 Il RAW: cosa ti dà e cosa ti costa

Attiva le **copie RAW** (`Impostazioni fotocamera → Formati avanzati`). In
modalità Pro ogni scatto salverà un `.dng` da 25–30 MB accanto al JPEG/HEIF.

**Cosa ti dà il RAW:**

- **gamma dinamica recuperabile**: due o tre stop di ombre e un po' di luci che
  nel JPEG sono già buttati via;
- **bilanciamento del bianco veramente modificabile** dopo lo scatto, senza
  degrado;
- **nessuna nitidezza e nessuna riduzione rumore imposte**: decidi tu quanto,
  e i risultati sono molto più naturali;
- niente artefatti da compressione.

**Cosa ti costa:**

- spazio (dieci volte il JPEG);
- **tempo**: un RAW va sviluppato, altrimenti è più brutto del JPEG. Sempre.
  Il JPEG del telefono è il risultato di anni di calibrazione; il tuo RAW
  appena aperto è piatto e spento. Il vantaggio arriva solo se lavori.

**Il consiglio pratico:** tieni le copie RAW **attive**. Costano solo spazio, e
il JPEG lo hai comunque. Le userai in una foto su venti — ma sarà la foto a cui
tieni.

---

## 6.5 Tre ricette da modalità Pro

### Scie di auto notturne
```
Treppiede (obbligatorio)
ISO 50 · SPEED 8–15 s · WB 3800 K · FOCUS manuale sull'infinito
Timer 2 s per non far tremare lo scatto
```

### Cascata setosa in pieno giorno
```
Appoggio solido o treppiede
ISO 50 · SPEED 1/4 – 1 s · EV −0.7
Se è troppo luminoso: non puoi chiudere il diaframma, quindi riprova
all'ombra o all'ora blu
```

### Concerto / teatro
```
A mano libera, obiettivo 1x o 3x
ISO 1600–3200 · SPEED 1/250 s · EV −1.0 · WB 3200 K
Esponi per il volto illuminato dal faro, non per la sala
```

Altre venti ricette nel [capitolo 17](17-ricette.md).

---

## 6.6 L'errore da cui guardarsi

Il rischio della modalità Pro è **dimenticare le impostazioni**. Esci dal
concerto con ISO 3200 e 1/250 s impostati, il giorno dopo fotografi un panorama
e ti chiedi perché è tutto nero e rumoroso.

**Abitudine da prendere:** appena finita una sessione in Pro, riporta ISO e
SPEED su `AUTO` (tocca il valore e scorri fino ad AUTO) prima di chiudere
l'app. Trenta secondi che ti salvano una foto importante.

---

## Da ricordare

- La Pro **non è meglio** dell'automatico: è **controllo** al posto di elaborazione.
- Serve davvero in cinque casi: movimento al buio, pose lunghe, scene ingannevoli,
  coerenza fra scatti, RAW.
- **Il tempo di posa viene prima**, l'ISO si adatta.
- Usa l'**istogramma** ed **esponi per le luci**.
- Il **WB in Kelvin** è la leva creativa più trascurata del telefono.
- Rimetti tutto su **AUTO** quando hai finito.

---

[← Capitolo 5](05-zoom.md) · [Indice](README.md) · [Capitolo 7 →](07-expert-raw.md)
