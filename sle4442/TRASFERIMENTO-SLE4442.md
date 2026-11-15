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

---
---

# APPENDICE ESAUSTIVA — NULLA ESCLUSO

---

## A. CATALOGO COMPLETO DI PRODOTTI, LINK E PREZZI CITATI

**Logic analyzer USB 24MHz 8CH (~10-15 €):**
- Open-Electronics (Italia) ~11,80 €: https://store.open-electronics.org/USB-Logic-Analyzer-24-MHz-8CH-Microcontroller-
- Elektor (UE) ~14,95 €: https://www.elektor.com/products/usb-logic-analyzer-8-ch-24-mhz
- SparkFun (TOL-18627) ~26,95 $: https://www.sparkfun.com/products/18627

**Logic analyzer STANDALONE con schermo+SD (LA104):**
- SainSmart ~124,99 $ (open-box ~89,99 $)
- Robotshop (Miniware) ~84,99 $: https://www.robotshop.com/products/seeedstudio-minidso-la104-logic-analyzer
- Nota: 4 canali 100MHz, schermo, microSD; NON ha decoder SLE44xx a bordo.

**Bus Pirate 5 (~40-46 €):**
- Reach.dog (Blinkinlabs) ~46,50 $: https://reach.dog/shop/blinkinlabs/products/bus-pirate-5
- The Pi Hut (UK) ~40,20 £: https://thepihut.com/products/bus-pirate-5-rev10-with-enclosure
- Documentazione: hardware.buspirate.com ; comando `sle4442` integrato in modalita' 2-wire.

**ESP32 DevKitC:**
- Mouser (Italia), parte 356-ESP32-DEVKITC32E: https://www.mouser.it/ProductDetail/356-ESP32-DEVKITC32E

**Socket / connettore smart card:**
- ATTUALE (consigliato), Amphenol FCI 7431E0525S01LF (8+2, through-hole) — Digi-Key Italia:
  https://www.digikey.it/it/products/detail/amphenol-icc-fci/7431E0525S01LF/1528152
- OBSOLETO (usato dalla PCB cuvoodoo), FCI 52400: broker 773grp
  https://www.773grp.com/collections/memory-connectors/products/52400-25alf-amphenol-icc-fci
  e ichome https://ichome.com/product-detail/amphenol-icc/52400-22alf
- AliExpress economico: cercare `smart card connector 8 pin` (contatti a molla, carta intera)

**Adattatore pass-through / interposer:**
- Kuhn "ISO 7816 Interface Monitor" (progetto, file PS/PDF, no Gerber):
  https://www.cl.cam.ac.uk/~mgk25/cardmonitor/
- cuvoodoo "ID-1 proxy" (progetto, GERBER pronti, connettore FCI 52400 obsoleto):
  https://git.cuvoodoo.info/kingkevin/id-1_proxy
  Cartelle: source/ (FCI_52400.fp, ID-1.fp, proxy.fp), fabrication/ (*.gbr + *.cnc),
  print/ (FCI_52400.pdf, ID-1.pdf, proxy.pdf). Spessore PCB 0,8 mm. Licenza non dichiarata.
- SIMtrace "Smart Card FPC Cable (full size)" ~21,42 € (prod. smartcard-fpc-kit):
  https://shop.sysmocom.de/SIMtrace-Smart-Card-FPC-Cable-full-size/smartcard-fpc-kit
  Contenuto: la scheda-linguetta con connettore FPC + cavo FFC 10 cm. Pad X1: VCC RST CLK
  AUX1 / GND VPP I/O AUX2. NON ha slot per la carta.
- Dispositivo SIMtrace2 ~101,15 € (ESAURITO), per SIM ASINCRONE, NON per SLE4442:
  https://shop.sysmocom.de/SIMtrace2-Hardware-Kit/simtrace2-kit
  Kit: dispositivo + cavo USB A-miniB + 4 adattatori FPC per SIM 2FF.
  Progetto: https://osmocom.org/projects/simtrace2
- Strumenti professionali (tutto-in-uno, migliaia di €): Micropross, COMPRION.

**Carte vergini / compatibili:**
- SLE4442 vergine bianca: eBay es. https://www.ebay.com/itm/201677192015 (20 pz ~16 $),
  ~35 $ per 100 pz.
- FM4442 (clone Fudan, 100% compatibile): usmartcards
  https://usmartcards.co.uk/fm4442-(replacement-for-sle4442)-white-pvc-card-gloss-finish
- SLE5542 (successore Infineon, compatibile).
- Carte a PROCESSORE (NON compatibili con SLE4442): "64 Kbit ATMega chipcard"
  (ATMega8515 + 24C64) ~9 € su WB Electronics / Infinity USB (infinityusb.com, store,
  Chipcards CPU). Sono FunCard asincrone, NON emulano il 2-wire sincrono.

**Fili "piattine" per saldare sui contatti:**
- Filo smaltato 0,1 mm (magnet wire): https://www.amazon.it/s?k=filo+smaltato+rame+0.1mm
- Nastro rame conduttivo: https://www.amazon.it/s?k=nastro+rame+conduttivo+adesivo
- Cavo FFC flat: https://www.amazon.it/s?k=piattina+FFC+cavo+flat
- Filo wire-wrap 30AWG: https://www.amazon.it/s?k=filo+wire+wrap+30awg

**Software gratuiti:**
- PulseView (sigrok): https://sigrok.org/wiki/Downloads — pagina: https://sigrok.org/wiki/PulseView
- Tutorial PulseView (SparkFun): https://learn.sparkfun.com/tutorials/using-the-usb-logic-analyzer-with-sigrok-pulseview
- Zadig (driver WinUSB, Windows): https://zadig.akeo.ie
- Elenco decoder sigrok: https://sigrok.org/wiki/Protocol_decoders (cercare SLE44xx)
- Toolchain ESP32 Arduino: https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html

**Altri sniffer open-source citati:**
- MIMIK Smart Card Analyzer (OSH Park, ~48 $).
- cardmonitor di Markus Kuhn (Univ. Cambridge).

---

## B. DATI TECNICI COMPLETI (valori reali)

**ATR della carta dell'utente:** `3B 04 A2 13 10 91`

**Dump completo originale (256 byte):**
```
0000  A2 13 10 91 FF FF 81 15 FF FF FF FF FF FF FF FF
0010  FF FF FF FF FF D2 76 00 00 04 00 FF FF FF FF FF
0020  17 00 06 00 01 00 01 1C 43 90 00 00 00 00 00 00
0030  00 00 00 F1 00 00 05 00 00 7F 00 00 04 00 00 00
0040  00 FF 05 DC 00 0F 0F 05 DC 00 0F 0F FF FF FF FF
0050..00F0  tutto FF
```
- `A2 13 10 91` = inizio memoria, coincide con l'ATR (area identificazione).
- `D2 76 00 00 04` (offset 0x15) = identificativo applicazione registrato.
- `17 00 06 00 01 00 01 1C 43 90` (0x20) = probabile codice/ID carta (quello che l'impianto confronta).
- `05 DC` (0x43 e 0x47) = 1500 decimale, valori di configurazione.

**Status word visti:**
- `90 00` = OK.
- Present-code `90 07` = PSC corretto (contatore pieno, 3 tentativi).
- Present-code `90 03` = PSC ERRATO, contatore ora 03 (2 tentativi). *** E' successo davvero sull'originale con FFFFFF ***
- Present-code `90 00` = carta BLOCCATA (tentativi esauriti).

**Bit di protezione dell'originale:** `FF FF FF FF` (nessun byte protetto).

**Contatore errori letto:** `07` all'inizio; DOPO il tentativo FFFFFF e' passato a `03`.

**Dimensioni carta (ISO/IEC 7810 ID-1):** 85,60 x 53,98 x 0,76 mm; angoli raggio 3,18 mm.

**Posizione contatti (ISO/IEC 7816-2):**
- Area minima di ogni contatto: 2,0 x 1,7 mm.
- Colonne (dal bordo SINISTRO): C1-C4 da 10,25 a 12,25 mm; C5-C8 da 17,87 a 19,87 mm.
- Righe (dal bordo SUPERIORE, lato alto): C1/C5 19,23; C2/C6 23,47; C3/C7 27,71; C4/C8 31,95 mm (passo 4,24).
- Fonte precisa: ISO/IEC 7816-2:2007 Figura 2. (I valori delle righe C2/C3/C4 sono dedotti dal passo standard, non verificati riga per riga.)
- Il modulo dorato visibile e' ~12-13 mm (NON fissato da ISO).

**Assegnazione contatti:**
- C1 VCC (alimentazione), C2 RST (reset), C3 CLK (clock), C4 non usato,
  C5 GND (massa), C6 VPP (non usato), C7 I/O (dato), C8 non usato.
- SLE4442 usa: C1, C2, C3, C5, C7. Non usa C4, C6, C8.
- Per SNIFFARE il PSC servono SOLO: C3 (CLK), C7 (I/O), C5 (GND).

---

## C. TUTTI I COMANDI

**Pseudo-APDU ACS (via transmit, LSB gestito dal lettore):**
- SELECT_CARD_TYPE: `FF A4 00 00 01 06`
- READ_MEMORY: `FF B0 00 <addr> <len>`
- READ_ERROR_COUNTER: `FF B1 00 00 04`
- READ_PROTECTION_BITS: `FF B2 00 00 04`
- WRITE_MEMORY: `FF D0 00 <addr> <len> <dati>`
- PRESENT_CODE (PSC): `FF 20 00 00 03 <p1 p2 p3>`
- CHANGE_CODE: `FF D2 00 01 03 <p1 p2 p3>`

**Strumenti Python (nel repo):**
- `python dump_sle4442.py [--out file.bin] [--reader N] [--psc FFFFFF]`
- `python clona_sle4442.py sle4442_dump.bin [--psc FFFFFF] [--reader N] [--yes]`
- `python sle4442_gui.py` (GUI)
- Dipendenza: `pip install pyscard`. Tkinter incluso su Windows.

**Bus Pirate (2-wire) — pilotaggio della carta:**
- `m` -> scegli 2-WIRE ; `W` -> alimentazione ON (5 V) ; `P` -> pull-up ON ; `L` -> LSB first ;
  poi `sle4442` (digitarlo per l'uso; sintassi sotto-comandi varia con il firmware).
- Pull-up e massa comune OBBLIGATORI sul 2-wire.

**Collegamento socket -> Bus Pirate:**
C1->VOUT, C5->GND, C3->IO1, C7->IO0, C2->IO2. Logic analyzer su C3, C7, C5.

**Linux/Ubuntu per la GUI:** `sudo apt install pcscd libccid python3-tk python3-pyscard pcsc-tools`,
poi `sudo systemctl enable --now pcscd`, verifica con `pcsc_scan`, avvio `python3 sle4442_gui.py`.
In WSL serve agganciare il lettore con usbipd-win + pcscd dentro WSL.

**Cardpeek:** copiare `sle4442.lua` in `%APPDATA%\cardpeek\scripts\`, poi Analyzer -> "SLE 4442".

---

## D. FLUSSO CRONOLOGICO DELLA CONVERSAZIONE (ogni tappa)

1. Richiesta iniziale (da PDF): leggere/dumpare la SLE4442 con ACR39U. -> creati dump_sle4442.py,
   clona_sle4442.py, launcher, README; diagnosi del "buffer vuoto".
2. "traduci in italiano" -> tradotto il riepilogo.
3. "passo passo" -> guida passo-passo.
4. "ma con windows?" -> procedura solo Windows (Python, ZIP dal branch, ecc.).
5. Verifica Python 3.13.3; download ZIP; cambio branch su GitHub; esecuzione; DUMP RIUSCITO.
   (modalita' "Seleziona" della console bloccava i tasti: premere Esc.)
6. Spiegazione bit di protezione (FF FF FF FF = non protetti) e contatore (07) + confusione
   "ancora 3 tentativi" (bug di visualizzazione: il riepilogo leggeva il contatore PRIMA del test).
   -> corretto lo script.
7. Clonazione: come, e che il PSC NON si copia.
8. Sicurezza SLE4442: nessuna crittografia, PSC in chiaro, lettura libera, clonabilita', PSC 24 bit,
   attacchi power-glitch (da laboratorio).
9. Logic analyzer: cos'e', dove, come; standalone LA104; salvataggio su SD; "con smartphone?" (no);
   "con Arduino micro/nano?" (sniffer passivo possibile ma marginale); ESP32 (migliore).
10. Carte vergini (dove comprare), contatti adesivi (non esistono per contatti), trimmer/taglierine.
11. Bus Pirate / "analizzatore di bus" (attivo, non passivo).
12. "carte che fanno entrambe"/"come le MIFARE" -> distinzione contatto vs contactless; Proxmark3 e
    magic card sono per MIFARE/RFID, non per SLE4442 (a contatti).
13. Confermato: NON e' MIFARE, e' SLE4442.
14. FunCard ATMega (WB Electronics ~9 €): NON emulano la SLE4442 (protocollo async vs sync).
15. Emulatore: proprieta' (tutto controllabile, PSC visibile/loggabile); ma e' scheda DIY, non carta;
    cattura il PSC solo se messo nel dispositivo che SCRIVE.
16. Nessuna carta compatibile mostra il PSC (solo l'emulatore DIY).
17. Software "raw" che legge tutto: gia' fatto dai tool; il PSC resta mascherato (hardware), nessun
    software lo legge.
18. Spiegata la memoria di sicurezza (contatore + posizione PSC mascherata).
19. "aumentare il contatore con un comando": NON possibile (anti-brute-force).
20. "clono anche la password?": NO (non e' nel dump).
21. "area di sicurezza... se si puo' scrivere e' accessibile?": scrittura e lettura separate; il PSC
    si scrive (col PSC attuale) ma non si legge (mascherato in hardware).
22. Cambiare la password: comando CHANGE_CODE, serve il PSC attuale. Se dimenticato: non si cambia,
    si bruciano tentativi, nessun recupero software; usare una vergine nuova.
23. "emulare inclusa la parte PSC": l'emulatore riproduce tutto, ma per avere il PSC VERO dell'originale
    bisogna conoscerlo (non leggibile).
24. Interposer: Kuhn, cuvoodoo, SIMtrace. Link dati. FCI 52400 OBSOLETO (snag).
25. Disegno carta + contatti (ISO), versione DALTONICO-SAFE, chip con etichette.
26. SIMtrace approfondito: adattatore FPC (com'e' fatto), dove va la carta (NON sull'adattatore),
    cosa c'e' in mezzo; SIMtrace2 ~101 € ESAURITO, per SIM asincrone, non per SLE4442.
27. Versione didattica "socket + ESP32/Bus Pirate + analizzatore": collegamenti, forme d'onda.
28. Il Bus Pirate non ha fessura: la carta va nel socket collegato con 5 fili.
29. Frustrazione dell'utente per i giri a vuoto e il connettore obsoleto; richiamo a non dire
    "capitolo chiuso". -> approccio pratico reale: socket + Bus Pirate + analizzatore.
30. Contatti per sniffare il PSC: C3 (CLK), C7 (I/O), C5 (GND). Socket su Amazon (difficile; meglio
    Digi-Key 7431E o AliExpress).
31. Richiesta di TRASFERIMENTO completo verso un'altra intelligenza -> questo documento.

---

## E. ELENCO DIAGRAMMI SVG (in sle4442/docs/) E COSA MOSTRANO

- carta-contatti.svg: formato ID-1 con quote + mappa contatti ISO-7816-2 con posizioni.
- chip-contatti.svg: chip ingrandito, ogni contatto etichettato (C3/C7/C5 evidenziati).
- interfaccia-fisica.svg: carta nel socket, contatti a molla, pin ai fili.
- forme-donda-2wire.svg: CLK/IO, START, 8 bit LSB-first, STOP, esempio byte 0x22.
- buspirate-collegamento.svg: carta nel socket, Bus Pirate, 5 fili (VOUT/GND/IO1/IO0/IO2).
- fpc-adattatore.svg: 3 zone dell'adattatore FPC (estremita' carta, pad X1, connettore FPC).
- fpc-modo-b.svg: adattatore FPC nel proprio ACR39U + socket sui pad X1 + analizzatore.
- carta-con-fpc.svg: dove va la carta con l'adattatore (socket o SIMtrace2, NON sull'adattatore).
- socket-fpc-collegamento.svg: i 5 fili tra pad X1 e pin del socket.
- interposer-schema.svg: assemblaggio dell'interposer (dov'e' lo slot/connettore).

Tutti i diagrammi sono DALTONICO-SAFE (motivi + bordi + etichette, palette blu/arancio/nero).

---

## F. REGOLE DI ATTRIBUZIONE GIT (per nuovi commit)
Terminare i messaggi di commit con:
```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014Vbqn7wvH8YuhhdU3RGB1Y
```
(La riga del modello e' cambiata durante la sessione: usare quella indicata dall'ambiente al momento.)
