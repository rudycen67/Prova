# DETTAGLI COMPLETI — Spiegazioni per esteso (Progetto SLE4442)

> Companion di TRASFERIMENTO-SLE4442.md. Qui OGNI argomento e' scritto per
> esteso, in dettaglio, come e' stato spiegato nella conversazione. Nulla
> riassunto. Da leggere insieme al documento principale.

---

## 1. PERCHE' I PRIMI TENTATIVI RESTITUIVANO UN BUFFER VUOTO []

Il rapporto tecnico iniziale pilotava la carta con `connection.control(IOCTL_CCID_ESCAPE, ...)`
e un payload proprietario tipo `FF DE 00 00 01 02`. Era sbagliato per due ragioni.

**Primo errore: canale sbagliato.** I comandi per le memory card ACS (ACR38/ACR39) sono
"pseudo-APDU" e vanno inviati sul **canale dati PC/SC**, cioe' con `connection.transmit()`
(che sotto chiama SCardTransmit), dopo un normale SCardConnect. Il canale `control()` /
escape serve ad altro (configurazione del lettore), NON a leggere o scrivere la carta.
Usandolo per leggere la carta si ottengono risposte vuote.

**Secondo errore: manca SELECT_CARD_TYPE.** Prima di qualunque lettura bisogna dire al
firmware del lettore quale carta sta pilotando, con `FF A4 00 00 01 06` (0x06 = famiglia
2-wire SLE4432/SLE4442/SLE5532/SLE5542). Senza questo comando il firmware NON attiva la
gestione del protocollo sincrono a 2 fili, quindi ogni `FF B0 ...` torna vuoto.

**Conseguenza importante:** NON serve nessun bit-banging dei segnali Clock/Data, ne' alcuna
escape proprietaria. Il firmware dell'ACR39U implementa gia' da solo il protocollo sincrono
a 2 fili: una volta selezionato il tipo carta, pilota lui i segnali fisici. Si inviano solo
le pseudo-APDU standard ACS con transmit().

---

## 2. IL SET DI COMANDI ACS, OGNI COMANDO SPIEGATO

(Fonte: ACS ACR39 Series Reference Manual, paragrafo 8.4, famiglia SLE4432/SLE4442/SLE5532/SLE5542.)

**SELECT_CARD_TYPE — `FF A4 00 00 01 06`**
Seleziona il tipo carta. 0x06 e' il codice ACS della famiglia 2-wire della SLE4442.
Risposta: `90 00`. Va dato una volta, subito dopo connect, prima di tutto il resto.

**READ_MEMORY_CARD — `FF B0 00 <ByteAddress> <MEM_L>`**
Legge la memoria principale. P2 = indirizzo del byte, Le = numero di byte da leggere.
Risposta: i byte letti + `90 00`. La lettura NON richiede il PSC.
Nota pratica: la lettura unica dei 256 byte con `FF B0 00 00 00` su alcuni firmware torna
incompleta; per robustezza si legge a blocchi di 16 byte (indirizzi 0x00, 0x10, ... 0xF0).

**READ_PRESENTATION_ERROR_COUNTER — `FF B1 00 00 04`** (solo SLE4442/SLE5542)
Legge la memoria di sicurezza: 4 byte = `<ERRCNT> <DUMMY1> <DUMMY2> <DUMMY3>` + `90 00`.
ERRCNT e' il contatore errori: 07h = ultima verifica corretta; 00h = carta bloccata
(tentativi esauriti); altri valori = ultima verifica fallita. I tre DUMMY sono dove sta il
PSC, ma escono MASCHERATI (byte fittizi), mai il valore reale.

**READ_PROTECTION_BITS — `FF B2 00 00 04`**
Legge i bit di protezione dei primi 32 byte: 4 byte PROT + `90 00`.
Regola dei bit di protezione: '1' = byte scrivibile, '0' = byte protetto in scrittura
(programmazione irreversibile).

**WRITE_MEMORY_CARD — `FF D0 00 <ByteAddress> <MEM_L> <dati>`**
Scrive dati nella memoria principale. Richiede che prima sia stato presentato il PSC corretto.
Risposta: `90 00`.

**WRITE_PROTECTION_MEMORY_CARD — `FF D1 00 <ByteAddress> <MEM_L> <dati>`**
Programma i bit di protezione (irreversibile). Non usato dagli strumenti del progetto.

**PRESENT_CODE_MEMORY_CARD — `FF 20 00 00 03 <p1 p2 p3>`** (solo SLE4442/SLE5542)
Presenta il PSC (3 byte) per sbloccare la scrittura. Procedura interna del chip:
1. cerca un bit '1' nel contatore errori e lo porta a '0' (decrementa, cioe' "consuma" un
   tentativo); 2. confronta il codice presentato con quello memorizzato; 3. se combacia,
   azzera il contatore a 0x07. Risposta: SW1=90h, SW2=ErrorCnt (07 = corretto; 00 = bloccata;
   altro = fallito).

**CHANGE_CODE_MEMORY_CARD — `FF D2 00 01 03 <p1 p2 p3>`** (solo SLE4442/SLE5542)
Cambia il PSC. Va eseguito DOPO aver presentato con successo il PSC ATTUALE corretto.
Risposta: `90 00`.

---

## 3. STRUTTURA DELLA MEMORIA, PER ESTESO

La SLE4442 ha tre zone di memoria distinte.

**Memoria principale: 256 byte.**
E' dove stanno i dati utili. Lettura SEMPRE libera (nessun PSC). Scrittura solo dopo aver
presentato il PSC corretto. Nella carta dell'utente, i dati reali stanno nei primi ~0x50
byte; dal 0x50 in poi e' tutto 0xFF (EEPROM vuota).

**Memoria di protezione: 32 bit (4 byte).**
Proteggono in scrittura i primi 32 byte della memoria principale. Ogni bit a '0' "congela"
irreversibilmente il byte corrispondente (non si riscrive mai piu', nemmeno col PSC). Nella
carta dell'utente erano tutti a '1' (`FF FF FF FF`): nessun byte congelato.

**Memoria di sicurezza: 4 byte.**
- Byte 0: contatore errori (solo i 3 bit bassi contano -> massimo 3 tentativi).
- Byte 1, 2, 3: il PSC (la password di 3 byte).
Quando leggi questa zona (`FF B1`), il contatore esce vero, ma i 3 byte del PSC escono
MASCHERATI (il chip ci mette sopra byte fittizi). Il PSC fisicamente e' li', salvato in
chiaro nella EEPROM, ma il percorso di lettura verso il pin I/O e' bloccato in hardware per
quei 3 byte.

---

## 4. IL PSC (PASSWORD), TUTTO QUELLO CHE C'E' DA SAPERE

**Dove sta:** nella memoria di sicurezza, byte 1-3 (dopo il contatore).

**Default di fabbrica:** le carte vergini hanno PSC `FF FF FF`.

**Perche' non si legge:** il chip ha tre percorsi verso quei 3 byte:
1. Scrittura (dall'esterno verso il chip): permessa, ma solo dopo aver presentato il PSC
   attuale (CHANGE_CODE). Non e' accesso libero.
2. Uso interno (confronto): quando presenti un PSC, il chip legge quello memorizzato DENTRO
   di se' e lo confronta. Questo percorso non esce mai dal chip.
3. Lettura verso l'esterno (sul filo I/O): BLOCCATA in hardware; il comando di lettura di
   quell'area restituisce byte fittizi.
In pratica il PSC puo' ENTRARE (scrittura) ed essere USATO dentro (confronto), ma non puo'
USCIRE (lettura). "Scrivibile" non vuol dire "leggibile": sono circuiti separati.

**Si potrebbe estrarre fisicamente?** In teoria si', con un attacco a livello di chip
(decapsulare il chip e microsondare la EEPROM, o analisi di potenza/glitch), perche' li'
dentro e' in chiaro. E' roba da laboratorio, strumenti costosi, distruttiva: non alla portata
normale. Ma e' uno dei motivi per cui la SLE4442 non e' vera sicurezza.

**La clonazione NON copia il PSC.** Il dump sono i 256 byte di memoria principale; il PSC sta
nell'area di sicurezza mascherata e in lettura non esce. Quindi il clone riceve i dati
identici ma tiene il PSC della vergine (`FFFFFF`). Funziona lo stesso perche' in lettura il
PSC non si usa mai, e l'impianto riconosce la carta leggendo la memoria.

**Come si potrebbe conoscere il PSC vero dell'originale:** solo (a) sniffando una SCRITTURA
reale (il PSC viaggia in chiaro su I/O quando qualcuno lo presenta), o (b) attacco fisico sul
chip. Spiando il LETTORE dell'allarme non si ottiene: l'allarme legge soltanto, e in lettura
il PSC non passa.

---

## 5. IL CONTATORE ERRORI E L'ANTI-BRUTE-FORCE, PASSO PER PASSO

Il PSC e' lungo 3 byte = 24 bit = circa 16,7 milioni di combinazioni. In teoria provabili,
ma la carta ha il contatore a 3 tentativi.

**Sequenza di verifica (in hardware):**
1. La carta PRIMA brucia un bit del contatore (decrementa): questo scrive in EEPROM, succede
   PRIMA del confronto.
2. POI confronta il PSC presentato con quello memorizzato.
3. Se e' giusto, RIAZZERA il contatore a 0x07.
Il punto cruciale: la carta non ti dice "giusto o sbagliato" senza prima decrementare. Non
esiste un comando "controlla senza consumare". E' esattamente cio' che blocca il brute-force.

**Valori del contatore:** 07 (3 tentativi) -> 03 (2) -> 01 (1) -> 00 (BLOCCATA in scrittura
per sempre). I bit a '1' sono i tentativi disponibili.

**Nessun software puo' evitare il decremento.** Nel momento in cui presenti un PSC, il
tentativo e' gia' consumato dal chip prima che il software legga la risposta. La "protezione"
di un buon programma puo' solo: non riprovare dopo un errore (per non bruciarne altri), e non
scrivere dati con PSC sbagliato. Ma il singolo tentativo bruciato non si recupera.

**Non esiste un comando per AUMENTARE il contatore.** Risale a 0x07 solo come effetto di un
PSC corretto. Scriverci sopra 0x07 richiederebbe comunque di sbloccare con il PSC, e i bit
sono a senso unico: il chip impedisce apposta di rialzarli a mano. Se si potesse, il
brute-force sarebbe banale. L'unico "trucco" e' il power-glitch hardware, che IMPEDISCE il
decremento (togliendo corrente nell'istante giusto), non lo fa salire; ed e' roba da laboratorio.

**Cosa e' successo all'utente:** ha provato `FFFFFF` sull'originale, rifiutato (SW=9003), e il
contatore e' passato da 07 a 03 (ha bruciato 1 tentativo, ne restano 2). Non deve tentare
altri PSC a caso: con 2 tentativi non si indovina un codice a 24 bit, si rischia solo di
bloccare la carta in scrittura. (La carta bloccata in scrittura continua comunque a leggersi
e a funzionare nell'allarme.)

---

## 6. LA CLONAZIONE, PER ESTESO

Clonare = copiare i 256 byte su una carta vergine. La vergine, con lo stesso contenuto,
diventa indistinguibile dall'originale per un lettore che confronta la memoria (la SLE4442
non ha un seriale crittografico non clonabile).

**Flusso:**
1. Leggi l'originale (nessun PSC) -> ottieni il dump dei 256 byte.
2. Metti la vergine, presenta il suo PSC (default `FFFFFF`), scrivi i 256 byte, rileggi e
   verifica byte per byte.

**Perche' funziona anche con PSC diverso:** l'impianto Bentel autorizza leggendo la memoria,
e la lettura non usa mai il PSC. Il clone ha dati identici; il suo PSC (`FFFFFF`) e' diverso
da quello dell'originale, ma non conta.

**Cosa NON si replica:** i bit di protezione (operazione irreversibile): se l'originale aveva
byte congelati, sul clone restano scrivibili. Per la memoria dati normale non cambia nulla.

**Lo strumento `clona_sle4442.py` / la GUI:** presenta il PSC UNA sola volta (un PSC errato
brucia un tentativo), scrive a blocchi di 16 byte, poi rilegge e confronta. Si ferma se il PSC
e' errato, per non bruciare tentativi.

---

## 7. PERCHE' LA SLE4442 E' CONSIDERATA DEBOLE (sicurezza, per esteso)

La chiave e' una sola: NON ha crittografia. E' una memoria con un lucchetto a password, non
un processore.

1. **Nessuna crittografia, nessun challenge-response.** La carta non cifra nulla e non dimostra
   la propria identita'. C'e' solo un confronto di password in chiaro.
2. **Il PSC viaggia in chiaro.** Quando un lettore sblocca la carta per scrivere, manda i 3
   byte del PSC in chiaro sui pin Clock/Data. Con un logic analyzer sui due fili, durante una
   normale transazione di scrittura, si cattura la password al primo colpo. Non si indovina:
   si ascolta.
3. **La lettura e' sempre libera.** I 256 byte si leggono senza alcun codice. Quindi qualunque
   "segreto" scritto in memoria e' gia' esposto.
4. **Nessun seriale crittografico.** Tutto cio' che definisce la carta sono i 256 byte,
   copiabili byte per byte. Un lettore che confronta solo il contenuto non distingue originale
   da clone.
5. **PSC a 24 bit.** Il brute-force diretto e' frenato dal contatore a 3 tentativi, ma esistono
   attacchi di power-glitch documentati che azzerano/impediscono il decremento del contatore.

Conseguenza: la SLE4442 non offre una vera difesa contro chi ha accesso fisico alla carta o al
lettore. Il controllo accessi moderno usa carte con crittografia (es. MIFARE DESFire) proprio
per questo. Confronto: una carta con crittografia non manda mai la chiave sul filo, fa un
botta-e-risposta matematico e la chiave resta dentro il chip; copiare la memoria non basta,
perche' non puoi copiare la chiave.

---

## 8. LO SNIFFING, COME FUNZIONA DAVVERO (per esteso)

**Principio.** Un logic analyzer e' PASSIVO: non parla, ascolta soltanto. Legge la tensione su
un filo migliaia/milioni di volte al secondo e la registra come 0 o 1 nel tempo. Non interferisce.

**Cosa serve e quali contatti.** Sulla SLE4442 i fili che contano sono due piu' la massa:
- C3 = CLK (clock): il metronomo, dice quando ogni bit e' valido.
- C7 = I/O (dato): il filo dei bit; e' QUI che passano i byte del PSC.
- C5 = GND (massa): riferimento comune.
Questi tre vanno al logic analyzer. C1 (VCC) e C2 (RST) servono alla carta per funzionare ma
non si "ascoltano" per leggere il PSC.

**La condizione decisiva.** Il PSC viene messo sui fili SOLO quando qualcosa SCRIVE sulla carta
(personalizzazione, ricarica, aggiornamento). Durante una semplice lettura non passa mai.
Quindi l'analizzatore mostra il PSC solo se catturi il momento di una SCRITTURA reale.

**Il problema pratico dell'aggancio.** Per catturare una scrittura non fatta da te, devi essere
elettricamente IN MEZZO tra il lettore vero e la carta. Non basta un socket: serve un interposer
pass-through (una "finta carta" che entra nel lettore, con la carta vera sopra/collegata, e i
segnali esposti). Per l'allarme Bentel che legge soltanto, non c'e' nessuna scrittura da
intercettare: quindi in pratica lo sniffing del PSC NON e' fattibile nel suo caso.

**La via didattica (pilotando tu la carta).** Se vuoi solo VEDERE il protocollo, metti la carta
in un socket, la piloti tu (Bus Pirate o ESP32), e l'analizzatore ascolta gli stessi pin. Cosi'
conosci gia' il PSC (`FFFFFF` su una vergine): serve a capire, non a scoprire un segreto.

---

## 9. IL PROTOCOLLO 2-WIRE BIT PER BIT (per esteso)

**Due fili e un ritmo.**
- CLK (clock): il metronomo, generato dal lettore. Sale e scende a impulsi.
- I/O (dato): alto = 1, basso = 0.
Regola base: il dato su I/O vale quando CLK e' ALTO (li' il bit e' stabile e si legge). Il dato
puo' cambiare mentre CLK e' basso.

**START e STOP** (punteggiatura, fatta muovendo I/O mentre CLK e' alto — cosa che durante i dati
non succede mai):
- START: I/O scende da 1 a 0 mentre CLK e' alto -> inizio messaggio.
- STOP: I/O sale da 0 a 1 mentre CLK e' alto -> fine messaggio.
(E' lo stesso principio dell'I2C, ma la SLE4442 non usa i bit di conferma ACK, ed e' LSB-first.)

**Come si legge un byte.** Tra START e STOP il lettore manda 8 impulsi di clock per byte. A ogni
impulso l'analizzatore guarda I/O sul fronte alto e segna 0 o 1. Otto bit = un byte. Essendo
LSB-first, il PRIMO bit arrivato e' il bit 0 (meno significativo): va riordinato.
Esempio: bit b0..b7 = 0,1,0,0,0,1,0,0 -> in ordine di peso (b7..b0) = 00100010 = 0x22.

**Com'e' fatto un comando.** Dopo lo START, in pratica 3 byte: comando, indirizzo, dato (o un
byte vuoto in lettura); poi altri impulsi di clock per l'operazione interna.

**Il momento della password.** Per sbloccare la scrittura, il lettore esegue la verifica del
PSC; al passo di confronto invia i 3 byte del PSC uno a uno verso la memoria di sicurezza. E'
li' che i 3 byte del PSC passano su I/O, come qualsiasi altro dato, in chiaro.

**Come l'analizzatore ricostruisce tutto.** Registra CLK e I/O nel tempo; il decoder SLE44xx di
PulseView trova START/STOP, campiona I/O a ogni CLK alto, raggruppa 8 bit (LSB-first) in byte,
riconosce i comandi e mostra, per esempio, "Compare Verification Data: FF FF FF" (il PSC).

---

## 10. GLI STRUMENTI HARDWARE, UNO PER UNO (per esteso)

**Logic analyzer USB economico (~10-15 €).** Scatolina/scheda USB con 8 (o 16) pin di ingresso
e cavetti con pinzette. Collegato al PC via USB, registra i livelli logici. Software gratuito:
PulseView/sigrok, che mostra le forme d'onda e le decodifica (decoder SLE44xx incluso). Su
Windows serve assegnargli il driver WinUSB con Zadig. E' PASSIVO: ascolta. Per la SLE4442 (bus
lento, decine di kHz) va benissimo.

**Logic analyzer STANDALONE (LA104).** Tascabile con schermo, batteria, microSD: funziona senza
PC. 4 canali, 100 MHz. Ma NON ha un decoder smart-card a bordo, quindi decodificare la SLE4442
sul suo schermino e' scomodo; conviene comunque PulseView al PC. Piu' caro (~90-120 €).

**Bus Pirate.** NON e' un analizzatore passivo: e' uno strumento ATTIVO che parla ai chip.
Collegato al PC via USB, in un terminale scegli il bus (I2C, SPI, UART, 2-wire...) e digiti
comandi; lui genera i segnali sui pin. Il modello 5 ha schermo, microSD, pull-up integrate.
Per la SLE4442 ha il comando integrato `sle4442` (reset, ATR, dump, unlock con PSC, scrittura).
NON ha una fessura: la carta va in un socket collegato ai suoi pin con 5 fili. Da solo ti mostra
i dati nel terminale; col logic analyzer in parallelo vedi anche le forme d'onda e il PSC.

**ESP32 / Arduino.** Un microcontrollore puo' fare da sniffer passivo (interrupt sul CLK,
campiona I/O, assembla i byte, stampa via seriale) o da lettore (master) del 2-wire. L'ESP32
(240 MHz) e' piu' affidabile dell'Arduino AVR (16 MHz) per questo. ATTENZIONE: le GPIO dell'ESP32
sono a 3,3 V e NON tollerano 5 V; se il bus e' a 5 V serve un partitore. Lo sniffer passivo ESP32
e' nel repo (scheletro didattico). Per pilotare la carta servirebbe un firmware da lettore (piu'
lavoro; il Bus Pirate ce l'ha gia' pronto).

**SIMtrace (adattatore FPC + dispositivo SIMtrace2).** Sistema per spiare/emulare SIM. L'adattatore
FPC (~21 €) e' la "finta carta" che entra nel lettore, con pad di test X1 (VCC RST CLK GND VPP I/O)
e un connettore FPC che va, via cavo flat, al SIMtrace2 (~101 €, esaurito). La carta vera NON va
sull'adattatore: va al SIMtrace2. CRUCIALE: il firmware SIMtrace decodifica solo l'ISO-7816
ASINCRONO (SIM, carte a processore T=0/T=1), NON il 2-wire SINCRONO della SLE4442. Quindi anche
col sistema completo la tua carta non viene decodificata dal suo software: serve comunque il logic
analyzer sui pad X1. Strada costosa e inadatta: scartata.

**Interposer open-source (Kuhn / cuvoodoo).** Scheda a forma di carta che fa da pass-through:
slot per la carta + linguetta nel lettore + pin per l'analizzatore, tutto su una sola PCB (0,8 mm).
Si FABBRICA (ordini la PCB + saldi un connettore smart card). Il cuvoodoo usa il connettore FCI
52400, OBSOLETO: e' lo snag che rende la strada poco pratica. Il Kuhn fornisce i file in PS/PDF
(da convertire in Gerber); il cuvoodoo fornisce i Gerber pronti (nel pacchetto cuvoodoo-interposer.zip).

**Socket smart card.** Il connettore in cui si infila la carta vera: i contatti a molla toccano
il chip (nessuna saldatura sulla carta), i piedini danno i segnali C1-C8. ATTUALE e disponibile:
Amphenol FCI 7431E0525S01LF (Digi-Key). Su Amazon si trova a fatica (soprattutto lettori USB
sigillati, inutili per il tap). Su AliExpress economico.

---

## 11. LE CARTE: SLE4442 vs COMPATIBILI vs PROCESSORE vs MIFARE (per esteso)

**Compatibili drop-in con la SLE4442** (stesso protocollo sincrono 2-wire, un clone ci funziona):
- SLE4442 (Infineon, originale).
- FM4442 (Fudan): clone diretto, 100% compatibile.
- SLE5542 (Infineon): successore pin- e protocollo-compatibile.
Tutte e tre: PSC mascherato (non leggibile). Sono le carte giuste da comprare per clonare.

**Carte a PROCESSORE (FunCard, es. ATMega8515 + 24C64, ~9 €):** sono piccoli computer in formato
carta, programmabili. Usano ISO-7816 ASINCRONO. NON possono emulare la SLE4442: su C3 ricevono il
clock della CPU, mentre nel 2-wire C3 e' il ritmo dei bit; e' un conflitto che rende l'emulazione
impraticabile. Non esiste una FunCard "modalita' SLE4442".

**MIFARE (e simili):** sono CONTACTLESS (RFID 13,56 MHz), si avvicinano al lettore. Mondo diverso
dalla SLE4442 (a contatti). Per le MIFARE esistono gli strumenti tutto-fare (Proxmark3, Chameleon,
Flipper) e le "magic card". Ma non c'entrano con la SLE4442. L'ACR39U non legge le MIFARE, e il
Proxmark3 non legge la SLE4442. Verifica chiave: se la chiave si INFILA (a contatti) e' SLE4442;
se si AVVICINA (contactless) e' un'altra tecnologia. L'utente ha confermato: e' SLE4442 a contatti.

---

## 12. EMULATORI (per esteso)

Un emulatore e' un microcontrollore (con clock proprio) programmato per "fare finta" di essere la
carta. Siccome il firmware lo scrivi tu, controlli tutto: i 256 byte, i bit di protezione, il
contatore (lo puoi rendere non-bloccabile), e il PSC.

A differenza di un chip vero, sull'emulatore il PSC e' VISIBILE: puoi impostarlo, farlo leggere in
chiaro, e soprattutto LOGGARE qualunque PSC un lettore gli presenta. Quindi l'emulatore e' una
"trappola per il PSC": messo al posto della carta nel dispositivo che SCRIVE, cattura il PSC in
chiaro quando quello lo presenta (senza logic analyzer).

Limiti: (a) cattura il PSC solo se c'e' una scrittura; (b) serve accesso al dispositivo che scrive
le carte; (c) e' una SCHEDA DIY (ESP32/STM32 + firmware), NON una carta da infilare, e non esiste
come prodotto commerciale. Per avere il PSC VERO dell'originale e metterlo nell'emulatore bisogna
comunque CONOSCERLO (non leggibile), quindi i dati si emulano perfetti ma il PSC resta ignoto senza
cattura.

Nota: NESSUNA delle carte compatibili (SLE4442/FM4442/SLE5542) mostra il PSC — e' sempre mascherato.
La proprieta' "PSC visibile" ce l'ha solo l'emulatore DIY.

---

## 13. CAMBIARE IL PSC E PSC DIMENTICATO (per esteso)

Si cambia con CHANGE_CODE (`FF D2 00 01 03 <nuovo PSC>`), ma SOLO dopo aver presentato il PSC
ATTUALE corretto (`FF 20 00 00 03 <PSC attuale>`). Quindi serve il permesso, come per scrivere i
dati. Sul clone/vergine (PSC `FFFFFF` noto) si puo'; sull'originale (PSC sconosciuto) no.

Se cambi il PSC e poi DIMENTICHI quello nuovo: non potrai piu' scrivere/azzerare quella carta, e
dopo 3 tentativi sbagliati la blocchi in scrittura per sempre. Nessun recupero software; solo
attacco fisico da laboratorio. La carta continua comunque a LEGGERSI e a funzionare nei sistemi
che la leggono. Consiglio pratico: se dimentichi il PSC di un clone, non indovinare a caso: prendi
una vergine nuova (PSC `FFFFFF`) e riclona. Se sperimenti il cambio PSC, fallo su una vergine di
scorta e SEGNATI il nuovo codice. Per l'uso reale conviene NON cambiare il PSC, tenerlo a `FFFFFF`.

---

## 14. IL PERCORSO PRATICO FINALE (per esteso)

Per la SLE4442 NON esiste un prodotto pronto, "compra e usa", economico, per sniffare. Ogni strada
richiede almeno qualche filo. L'unica via senza fili sarebbe uno strumento professionale da migliaia
di euro (Micropross, COMPRION).

La via pratica realizzabile per CAPIRE il protocollo (pilotando tu la carta):
`socket smart card (con header) + Bus Pirate (comando sle4442) + logic analyzer`.
- Tutto gira attorno al SOCKET, dove i contatti escono su PIEDINI NORMALI (non i pad minuscoli
  dell'adattatore FPC). Ci saldi una fila di header (pin grossi, 5 minuti) o lo infili in breadboard.
- Il Bus Pirate si collega ai piedini con 5 cavetti jumper (spinotti, non saldature fini):
  C1->VOUT, C5->GND, C3->IO1, C7->IO0, C2->IO2.
- Il Bus Pirate, col comando `sle4442`, legge la carta e mostra i dati; il logic analyzer sui pin
  C3/C7/C5 + PulseView mostra le forme d'onda e il PSC che presenti tu.
Il limite onesto: catturare un PSC SCONOSCIUTO spiando il lettore reale mentre scrive non ha una
soluzione pratica consumer; quella parte si lascia stare.

---

## 15. DIMENSIONI E POSIZIONI (per esteso)

Carta (ISO/IEC 7810 ID-1): 85,60 x 53,98 x 0,76 mm; angoli raggio 3,18 mm.
Modulo chip in alto a sinistra. Campo contatti (ISO/IEC 7816-2): area minima di ogni contatto
2,0 x 1,7 mm. Colonne dal bordo sinistro: C1-C4 da 10,25 a 12,25 mm; C5-C8 da 17,87 a 19,87 mm.
Righe dal bordo superiore (lato alto del contatto): C1/C5 19,23; C2/C6 23,47; C3/C7 27,71;
C4/C8 31,95 mm (passo 4,24). Fonte precisa: ISO/IEC 7816-2:2007, Figura 2. Il modulo dorato
visibile e' ~12-13 mm (non fissato da ISO). Numerazione: C1 in alto a sinistra, C5 in alto a destra.
I disegni SVG nel repo sono tutti daltonico-safe (motivi + bordi + etichette, blu/arancio/nero).

---

## 16. TUTTI I SETUP (Windows / Ubuntu / WSL / Cardpeek) (per esteso)

**Windows.** Installa Python 3 (spunta "Add Python to PATH"). Scarica lo ZIP del branch
`claude/new-session-qpfdur` da GitHub (dopo aver cambiato branch), estrai. I launcher `.cmd`
installano `pyscard` da soli e avviano. Servizio Smart Card (SCardSvr) attivo. Nota: la modalita'
"Seleziona" della console blocca i tasti (premere Esc).

**Ubuntu/Linux.** `sudo apt install pcscd libccid python3-tk python3-pyscard pcsc-tools`, poi
`sudo systemctl enable --now pcscd`, verifica con `pcsc_scan` (deve comparire ACS ACR39U), avvio
`python3 sle4442_gui.py`.

**WSL.** Il lettore USB non si vede da solo: agganciarlo con usbipd-win (come il Proxmark3 del
progetto) e far girare pcscd dentro WSL; la grafica (Tkinter) funziona con WSLg su Windows 11.

**Cardpeek.** Gli script di serie coprono solo carte a processore; questo repo fornisce
`sle4442.lua` che invia i comandi ACS via `card.send()`. Copiarlo in `%APPDATA%\cardpeek\scripts\`,
poi Analyzer -> "SLE 4442 (memory card)".

---
FINE DETTAGLI COMPLETI.
