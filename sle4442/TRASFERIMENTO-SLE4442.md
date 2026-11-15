# TRASFERIMENTO CONVERSAZIONE — Progetto SLE4442 / ACR39U

> Documento di passaggio di consegne per un'altra intelligenza (identica a chi
> ha lavorato finora). Contiene TUTTO: contesto, nozioni tecniche, lavoro
> svolto, stato attuale e istruzioni. Nessun punto escluso.

---

## 0. NOME E ARGOMENTO DELLA CONVERSAZIONE

**Nome:** Dump e clonazione di una smart card Infineon SLE4442 con lettore ACS
ACR39U (contesto iniziale: integrazione impianto allarme Bentel Kyo), e lunga
esplorazione su come "sniffare" (intercettare) il PSC (password) della carta.

**Repository di lavoro:** `github.com/rudycen67/Prova`
**Branch:** `claude/new-session-qpfdur`
Tutto il codice e i disegni sono gia' committati e pushati li'.

---

## 1. CHI E' L'UTENTE E COME TRATTARLO (IMPORTANTISSIMO)

- **Parla e scrive in ITALIANO.** Rispondi sempre in italiano.
- **E' DALTONICO.** Ogni disegno/diagramma deve essere leggibile senza affidarsi
  al solo colore: usa MOTIVI di riempimento (pieno/righe/puntini/diagonale),
  STILI di bordo diversi ed ETICHETTE di testo. Palette sicura: blu/arancio/nero,
  NON verde/rosso.
- **NON dirgli mai "capitolo chiuso", "non ti serve", "hai gia' finito",
  "fermiamoci qui".** Lo trova INVADENTE e QUASI OFFENSIVO. Gliel'ho ripetuto
  piu' volte e si e' giustamente arrabbiato. Vuole imparare e capire: assecondalo
  senza spingerlo a smettere.
- Vuole soluzioni **pratiche e reali**, non giri a vuoto. Si innervosisce con le
  esplorazioni circolari e i vicoli ciechi. Va' dritto al pratico.
- Vuole **link a prodotti singoli** (pagina del prodotto), NON pagine di ricerca
  con tanti prodotti. Quando apri una ricerca si lamenta.
- Preferisce **disegni/schemi** per capire: e' molto visivo. Usa SVG inviati come
  file (display render).
- Ha l'**ACR39U funzionante** e un **clone funzionante** sull'impianto.

---

## 2. IL PROBLEMA ORIGINALE E LA SOLUZIONE (gia' risolto)

**Rapporto iniziale (PDF):** l'utente non riusciva a leggere una SLE4442 con
l'ACR39U: i comandi restituivano un buffer vuoto `[]`. Aveva usato il canale
escape/IOCTL (`connection.control`) e un payload proprietario `FF DE ...`.

**Diagnosi/soluzione (fix):**
1. I comandi delle memory card ACS vanno inviati con **`connection.transmit()`**
   (canale dati PC/SC / SCardTransmit), NON con `control()`.
2. Prima di leggere serve **`SELECT_CARD_TYPE` = `FF A4 00 00 01 06`**
   (0x06 = famiglia 2-wire SLE4432/SLE4442). Senza, ogni `FF B0` torna vuoto.
Il firmware dell'ACR39U gestisce lui il protocollo sincrono 2-wire: niente
bit-banging, niente escape.

---

## 3. NOZIONI TECNICHE SULLA SLE4442 (set comandi ACS, da ACR39 Reference Manual 8.4)

| Operazione | Pseudo-APDU | Risposta |
|---|---|---|
| Seleziona tipo carta | `FF A4 00 00 01 06` | `90 00` |
| Leggi memoria | `FF B0 00 <addr> <len>` | dati + `90 00` |
| Leggi contatore errori PSC | `FF B1 00 00 04` | `EC xx xx xx 90 00` |
| Leggi bit di protezione | `FF B2 00 00 04` | `P1..P4 90 00` |
| Scrivi memoria | `FF D0 00 <addr> <len> <dati>` | `90 00` |
| Presenta PSC (sblocca scrittura) | `FF 20 00 00 03 <p1 p2 p3>` | `90 <EC>` |
| Cambia PSC | `FF D2 00 01 03 <p1 p2 p3>` | `90 00` |

**Struttura memoria:**
- Memoria principale: **256 byte**. Lettura libera (nessun PSC). Scrittura con PSC.
- Memoria di protezione: 32 bit (4 byte), proteggono i primi 32 byte. Scrittura
  IRREVERSIBILE.
- Memoria di sicurezza: 4 byte = **contatore errori (byte 0)** + **PSC (byte 1-3)**.
  Il PSC e' **mascherato in hardware**: in lettura escono byte fittizi (es. 00 00 00),
  mai il valore reale. Il chip lo usa solo internamente per il confronto.

**PSC (password):**
- Default di fabbrica delle carte vergini: **`FF FF FF`**.
- NON e' leggibile via software (mascherato). Si ottiene solo: (a) sniffando una
  SCRITTURA (il PSC viaggia in chiaro su I/O quando si presenta), o (b) attacco
  fisico sul chip (laboratorio).
- Clonare NON copia il PSC (non e' nel dump). Il clone tiene il PSC della vergine
  (`FFFFFF`), ha dati identici, e funziona perche' in LETTURA il PSC non si usa mai.

**Contatore errori (anti-brute-force):**
- Valori: `07` (3 tentativi) -> `03` (2) -> `01` (1) -> `00` (BLOCCATA in scrittura
  per sempre).
- Scende da solo a ogni PSC presentato (prima del confronto, in hardware): NESSUN
  software puo' evitarlo. Risale a `07` SOLO con il PSC corretto. Nessun comando
  per aumentarlo.
- CHANGE_CODE (cambio PSC) richiede di presentare prima il PSC ATTUALE corretto.

---

## 4. STATO DEL LAVORO (fatti accertati)

- **Il clone FUNZIONA** sull'impianto Bentel (confermato dall'utente). L'impianto
  autorizza leggendo la memoria; il PSC non e' richiesto in lettura.
- La **carta originale ha il PSC cambiato** dall'installatore: `FFFFFF` e' stato
  RIFIUTATO (SW=9003). Con quel tentativo e' stato **bruciato 1 dei 3 tentativi**
  (contatore ora a `03` = 2 rimasti). NON provare altri PSC a caso sull'originale.
- Dump reale dell'originale (prime righe, il resto e' FF):
  ```
  0000  A2 13 10 91 FF FF 81 15 FF FF FF FF FF FF FF FF
  0010  FF FF FF FF FF D2 76 00 00 04 00 FF FF FF FF FF
  0020  17 00 06 00 01 00 01 1C 43 90 00 00 00 00 00 00
  0030  00 00 00 F1 00 00 05 00 00 7F 00 00 04 00 00 00
  0040  00 FF 05 DC 00 0F 0F 05 DC 00 0F 0F FF FF FF FF
  ```
  Protezione: `FF FF FF FF` (nessun byte protetto). Contatore: era `07`, ora `03`.

---

## 5. FILE PRODOTTI (tutti nel repo, branch claude/new-session-qpfdur)

**Strumenti Python:**
- `sle4442/dump_sle4442.py` — legge 256 byte + protezione + contatore, dump hex, salva .bin.
- `sle4442/clona_sle4442.py` — scrive/clona un dump su vergine (present-code + write + verifica).
- `sle4442/sle4442_gui.py` — programma Windows con GUI (Tkinter): legge, scrive, azzera, salva/carica .bin.

**Launcher Windows (doppio clic):**
- `LEGGI-SLE4442.cmd`, `CLONA-SLE4442.cmd`, `SLE4442-GUI.cmd`.

**Altri strumenti:**
- `sle4442/cardpeek/sle4442.lua` — script per leggere la carta dalla GUI Cardpeek.
- `sle4442/esp32-sniffer/esp32_sle4442_sniffer.ino` — firmware ESP32 sniffer PASSIVO (scheletro didattico).

**Documentazione:**
- `sle4442/README.md` — diagnosi + set comandi.
- `sle4442/UBUNTU.md` — uso della GUI su Ubuntu/Linux (+ WSL con usbipd).
- `sle4442/cardpeek/README.md`, `sle4442/esp32-sniffer/README.md`.
- `sle4442/sniffing-didattico.md` — guida allo sniffing con logic analyzer + PulseView.
- `sle4442/docs/didattica-vedere-protocollo.md` — setup socket + pilota + analizzatore.

**Disegni SVG (tutti daltonico-safe):**
- `carta-contatti.svg` — formato ISO ID-1 (85,6 x 53,98 x 0,76 mm) + mappa contatti ISO-7816-2 con quote.
- `chip-contatti.svg` — chip ingrandito, ogni contatto etichettato in posizione (C3/C7/C5 da collegare).
- `interfaccia-fisica.svg` — carta nel socket, contatti a molla, pin ai fili.
- `forme-donda-2wire.svg` — forme d'onda CLK/IO (START, bit LSB-first, STOP), esempio byte 0x22.
- `buspirate-collegamento.svg` — carta nel socket, Bus Pirate con 5 fili.
- `fpc-adattatore.svg`, `fpc-modo-b.svg`, `carta-con-fpc.svg`, `socket-fpc-collegamento.svg`,
  `interposer-schema.svg` — tutta la parte SIMtrace/interposer.

---

## 6. ESPLORAZIONE HARDWARE PER LO SNIFFING (conclusioni gia' raggiunte)

Abbiamo esaminato TUTTE le strade per intercettare il PSC. Conclusioni:

- **Contatti da sniffare:** solo **C3 (CLK), C7 (I/O), C5 (GND)**. Il PSC viaggia su
  I/O, scandito dal clock, rispetto a massa.
- **Logic analyzer** USB 24MHz 8CH (~10 €) + **PulseView** (gratis, decoder SLE44xx)
  = lo strumento per vedere/decodificare le forme d'onda.
- **Interposer (per spiare il lettore reale):** nessuna soluzione pronta economica.
  - Kuhn / cuvoodoo = progetti OPEN da far PRODURRE (PCB 0,8 mm + saldare connettore).
    Il connettore del cuvoodoo e' un **FCI 52400 OBSOLETO** -> strada poco pratica.
  - SIMtrace (adattatore FPC ~21 € + dispositivo SIMtrace2 ~101 €) = e' per SIM
    ASINCRONE, NON decodifica il 2-wire della SLE4442. Pad X1 minuscoli, scomodi.
    STRADA SCARTATA come impraticabile.
- **Limite onesto e definitivo:** catturare un PSC SCONOSCIUTO spiando il lettore
  reale mentre scrive NON ha una soluzione pratica consumer. Lasciar perdere.

**La via pratica reale (per CAPIRE il protocollo, pilotando tu la carta):**
`socket smart card (con header) + Bus Pirate (comando sle4442) + logic analyzer`.
In questo modo PILOTI tu la carta (quindi conosci il PSC `FFFFFF`), vedi tutto il
protocollo e il present-code. Realizzabile, poche saldature (solo un header sui
piedini del socket, pin grossi), poi cavetti jumper.

---

## 7. DOVE SIAMO ARRIVATI (ultimo lavoro, in dettaglio)

L'utente ha capito (giustamente) che l'adattatore FPC SIMtrace e' scomodo (pad
minuscoli, connettore FPC fine su cui NON si saldano fili). Abbiamo concordato la
via pratica: **socket + Bus Pirate + logic analyzer**, dove la carta va nel socket
(contatti a molla, nessuna saldatura sulla carta) e i piedini escono comodi.

**Ultime richieste aperte:**
1. Trovare un **socket smart card acquistabile su Amazon** (difficile: su Amazon
   ci sono soprattutto lettori USB sigillati; i socket a componente stanno su
   AliExpress/Mouser/Digi-Key). Link affidabile dato: Amphenol FCI
   **7431E0525S01LF** su Digi-Key (attuale, in produzione). Alternativa economica:
   AliExpress `smart card connector 8 pin` (contatti a molla, carta intera).
2. Confermati i **contatti da sniffare: C3 (CLK), C7 (I/O), C5 (GND)**.

**Collegamento socket -> Bus Pirate (2-wire):**
C1(VCC)->VOUT, C5(GND)->GND, C3(CLK)->IO1, C7(I/O)->IO0, C2(RST)->IO2.
Poi, nel Bus Pirate: modalita' 2-wire, alimentazione 5V (`W`), pull-up ON (`P`),
LSB (`L`), comando `sle4442`. Pull-up e massa comune sono obbligatori.
Logic analyzer su C3, C7, C5.

---

## 8. PROSSIMI PASSI APERTI (da dove ripartire)

- Trovare/confermare il socket (Amazon o AliExpress o Digi-Key 7431E).
- Guidare l'utente nel collegamento socket -> Bus Pirate e nell'uso del comando
  `sle4442`.
- Eventualmente: sequenza esatta dei comandi Bus Pirate (reset, dump, present-code).
- Eventualmente: firmware ESP32 da LETTORE (master) se vuole l'ESP32 invece del
  Bus Pirate (lo sniffer passivo gia' nel repo e' un'altra cosa).

---

## 9. ISTRUZIONI OPERATIVE PER L'ALTRA INTELLIGENZA

1. Rispondi in **italiano**.
2. Disegni **daltonico-safe** (motivi + etichette, blu/arancio/nero).
3. **Non** dire "non ti serve / capitolo chiuso / fermiamoci". Assecondalo.
4. Vai **dritto al pratico**, niente giri a vuoto, **link a prodotti singoli**.
5. Il lavoro vive nel repo `rudycen67/Prova`, branch `claude/new-session-qpfdur`:
   clona quello per avere tutti i file. Committa li' i nuovi lavori (chiedi conferma
   prima di push se non sei sicuro).
6. Ricorda i fatti chiave: clone FUNZIONA; originale PSC cambiato (contatore a 03,
   2 tentativi, NON tentare PSC a caso); PSC non leggibile; sniffing PSC sconosciuto
   non praticabile; via pratica = socket + Bus Pirate + analizzatore per vedere il
   protocollo.
