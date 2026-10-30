# Sniffer SLE4442 con ESP32 (didattico)

Firmware di base per usare un **ESP32** come sniffer passivo del bus 2-wire
della SLE4442, al posto di "logic analyzer + PC". Ascolta CLK e I/O,
riconosce START/STOP, assembla i byte e li stampa sulla seriale. Durante una
scrittura (es. `PRESENT_CODE`) tra i byte compaiono i **3 byte del PSC**.

> Scopo **didattico**, sulla **tua** carta e il **tuo** lettore. Serve a
> capire il protocollo e a vedere il PSC in chiaro durante una scrittura che
> generi tu. Intercetta solo carte/lettori tuoi o autorizzati.

File: [`esp32_sle4442_sniffer.ino`](esp32_sle4442_sniffer.ino)

---

## Perche' ESP32 e non Arduino Nano/Micro

Il bus della SLE4442 e' lento (decine di kHz), ma l'ESP32 (240 MHz) gestisce
gli interrupt GPIO con molto margine e in modo piu' affidabile dell'AVR a
16 MHz. In piu' puoi leggere i risultati via USB-seriale, o estenderlo con
WiFi/Bluetooth o un display per non usare il PC.

---

## ATTENZIONE: livelli di tensione (leggi prima di collegare)

Le GPIO dell'ESP32 sono a **3.3V e NON tollerano 5V**. Molti lettori pilotano
la SLE4442 a **5V**: in quel caso **devi** abbassare i segnali, o danneggi
l'ESP32.

- **Partitore semplice 5V -> 3.3V** su CLK e su I/O:
  segnale --[ R1 = 10k ]--+--[ R2 = 20k ]-- GND, e prelevi sul nodo centrale.
- Oppure un **level shifter** bidirezionale 5V/3.3V.
- Se verifichi che lettore/carta lavorano a **3.3V**, puoi collegare diretto.
- Nel dubbio: **usa il partitore**.

Essendo solo in ascolto, l'ESP32 non pilota nulla: va benissimo un partitore
(non serve un buffer attivo).

---

## Collegamenti

Contatti ISO-7816 della SLE4442 (esposti da un **extender** per smart card):

| Contatto | Segnale | ESP32 |
|---|---|---|
| **C3** | CLK | GPIO 22 (via partitore) |
| **C7** | I/O | GPIO 21 (via partitore) |
| **C5** | GND | GND (massa comune OBBLIGATORIA) |
| C1 | VCC | NON collegare (lo da' il lettore) |
| C2 | RST | NON collegare |

```
  Carta -> Extender -> ACR39U -> USB -> PC (lancia la scrittura)
             │   │   │
            C3  C7  C5
             │   │   │
         [part][part]│
             │   │   │
          GPIO22 GPIO21 GND   (ESP32, solo ascolto)
             │
          ESP32 -> USB -> monitor seriale (PC o telefono)
```

I GPIO 21/22 sono un esempio: su alcune schede ESP32 vanno scelti pin liberi
e sicuri all'avvio (evita quelli di boot/strapping).

---

## Come si usa

1. Installa l'**IDE Arduino** e il supporto **ESP32** (Boards Manager:
   "esp32" di Espressif). Guida: https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html
2. Apri `esp32_sle4442_sniffer.ino`, seleziona la tua scheda ESP32 e la porta.
3. Regola se serve `PIN_CLK` / `PIN_IO` in cima al file.
4. Carica il firmware sull'ESP32.
5. Collega CLK/I/O/GND come sopra (con partitore se il bus e' a 5V).
6. Apri il **monitor seriale a 115200 baud**.
7. Sul PC genera una scrittura verso la carta:

   ```bat
   python dump_sle4442.py --psc FFFFFF
   ```

   (oppure `CLONA-SLE4442.cmd`).
8. Sul monitor seriale vedrai i messaggi tra `[START]` e `[STOP]`. Nella
   sequenza di verifica del codice compaiono i **3 byte del PSC** (con questo
   test: `FF FF FF`).

---

## Limiti (onesti)

- E' uno **scheletro didattico**, non uno strumento industriale: in condizioni
  di clock veloce o rumore puo' perdere qualche bit. Per catture affidabili, un
  **logic analyzer + PulseView** resta superiore.
- Non fa la decodifica completa dei comandi (comando/indirizzo/dato): stampa i
  byte grezzi di ogni messaggio. Il PSC lo riconosci perche', con `--psc
  FFFFFF`, vedrai `FF FF FF` nella sequenza di scrittura.
- Vale sempre il limite di fondo: il **PSC passa sul filo solo durante una
  scrittura**. Su una lettura non compare.

---

## Estensioni possibili

- **Display OLED** (I2C, SSD1306) per vedere i byte senza PC.
- **Decodifica dei comandi**: distinguere lettura/scrittura/compare e marcare
  esplicitamente i byte del PSC.
- **Timestamp** sugli eventi per misurare la frequenza di clock.
- **ESP32 + WiFi/BT**: inviare il tracciato al telefono.
