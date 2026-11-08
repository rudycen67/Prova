# Vedere il protocollo della SLE4442 (versione didattica)

Obiettivo: **osservare** il protocollo 2-wire e vedere il **PSC in chiaro**,
pilotando tu stesso la carta (una vergine con PSC noto `FFFFFF`). Non serve
intercettare nessuno: generi tu il traffico e lo guardi con il logic analyzer.

Idea: la carta sta in un **socket** che espone i contatti su pin; un **pilota**
(Bus Pirate o ESP32) parla alla carta; il **logic analyzer** ascolta gli stessi
pin e **PulseView** decodifica.

```
   [Pilota: Bus Pirate o ESP32] ──┐
                                   ├── CLK (C3) ─── pin socket ─── chip
                                   ├── I/O (C7) ─── pin socket ─── chip
                                   ├── VCC (C1), RST (C2), GND (C5)
   [Logic analyzer] ──────────────┘ (in parallelo su CLK, I/O, GND)
          │
          └── USB → PC → PulseView (decoder SLE44xx)
```

---

## Materiale

| Pezzo | A cosa serve | Dove cercare |
|---|---|---|
| **Socket smart card** (full-size, pin esposti) | tiene la carta e porta i contatti su pin | `ISO7816 smart card connector 8 pin` (AliExpress) |
| **Pilota** — *Bus Pirate* (consigliato) | parla alla carta, comando `sle4442` integrato | `bus pirate` (Amazon/AliExpress) |
| …oppure **ESP32** | pilota alternativo (serve firmware) | `ESP32 devkit` (Amazon/AliExpress) |
| **Logic analyzer** 24 MHz 8 canali | ascolta CLK/I/O | `USB logic analyzer 24MHz 8CH` |
| **PulseView** (sigrok) | decodifica, gratis | sigrok.org/wiki/Downloads |
| **Carta vergine SLE4442** | la carta di prova (PSC `FFFFFF`) | `SLE4442 blank card` |
| Breadboard + jumper | collegamenti | — |

Tensione: alimenta la carta a **3,3 V** (così è compatibile con le GPIO
dell'ESP32 senza partitori). Con il Bus Pirate usa 3,3 V o 5 V secondo la sua
modalita'.

---

## Collegamenti (pin del socket)

| Contatto | Va a |
|---|---|
| C1 (VCC) | alimentazione del pilota (3,3 V) |
| C5 (GND) | GND del pilota **e** GND dell'analizzatore (massa comune) |
| C2 (RST) | pin RST del pilota |
| C3 (CLK) | pin CLK del pilota **+** canale D0 dell'analizzatore |
| C7 (I/O) | pin I/O del pilota **+** canale D1 dell'analizzatore |

I pin CLK e I/O sono condivisi: il pilota li comanda, l'analizzatore li ascolta.

---

## Opzione A — Bus Pirate (la più semplice, consigliata)

1. Collega il Bus Pirate al socket secondo la tabella (VCC, GND, CLK=CLOCK,
   I/O=DATA, RST). Il Bus Pirate 2-wire usa IO0/SDA = I/O, IO1/SCL = CLK.
2. Apri un terminale seriale verso il Bus Pirate, entra in modalita' 2-wire,
   imposta **LSB** (comando `L`).
3. Usa il comando integrato `sle4442` per fare reset/dump/present-code.
   Durante il present-code manda il PSC in chiaro sul filo.
4. Nel frattempo il logic analyzer registra; in PulseView aggiungi il decoder
   **SLE44xx** (Clock=D0, Data=D1) e leggi i byte, incluso il PSC `FF FF FF`.

Nessun firmware da scrivere.

---

## Opzione B — ESP32 (serve firmware da lettore)

L'ESP32 deve implementare il protocollo 2-wire **da master**: sequenza di
reset, lettura memoria e present-code, pilotando CLK e I/O. E' piu' lavoro del
Bus Pirate e il timing va messo a punto. Se vuoi questa strada, nel progetto
puo' essere aggiunto un firmware "reader" dedicato (diverso dallo sniffer
passivo gia' presente in `sle4442/esp32-sniffer/`, che invece solo ascolta).

---

## Cosa vedrai

Nel tracciato di PulseView:

- la condizione **START** (I/O scende mentre CLK e' alto),
- i **byte** dei comandi (8 impulsi, LSB-first),
- la sequenza di **present-code** con i **3 byte del PSC** (`FF FF FF`).

E' la dimostrazione, sulla tua carta, che il PSC viaggia **in chiaro**.

---

## Promemoria

Qui conosci gia' il PSC (`FFFFFF`): serve per **capire** il protocollo, non per
scoprire un codice. Per l'uso reale della chiave non serve nulla di tutto
questo: il clone su carta vergine funziona gia'.

---

## Collegamento dettagliato: socket → Bus Pirate

I 5 fili (il pin del socket corrisponde al contatto della carta):

| Contatto carta | Pin Bus Pirate | Segnale |
|---|---|---|
| C1 | VOUT | VCC (alimentazione) |
| C5 | GND | massa |
| C3 | IO1 | CLK (clock) |
| C7 | IO0 | I/O (dato) |
| C2 | IO2 | RST (reset) |

Passi:
1. Dal datasheet del socket, individua i piedini C1, C2, C3, C5, C7.
2. Salda un header (o i fili) sui piedini del socket.
3. Collega i 5 cavetti secondo la tabella.
4. Inserisci la carta vergine nel socket.
5. Collega il Bus Pirate al PC (USB), apri il terminale seriale.
6. Configura il Bus Pirate:
   - modalita' 2-wire (`m` -> 2-WIRE);
   - alimentazione ON (`W`, 5 V);
   - pull-up ON (`P`) -- indispensabili sul 2-wire;
   - LSB first (`L`).
7. In 2-wire, usa il comando `sle4442` (digita `sle4442` per l'uso) per
   reset / dump / present-code.

Avvertenze:
- Le pull-up (passo 6) sono obbligatorie, altrimenti il filo dato non va.
- La massa (GND) deve essere comune a tutto; quando aggiungi il logic
  analyzer, il suo GND va sullo stesso GND.
- La sintassi esatta dei sotto-comandi `sle4442` puo' variare con la
  versione del firmware: controlla l'aiuto a bordo.
