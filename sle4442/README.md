# Dump SLE4442 con lettore ACS ACR39U

Estrae il dump completo di una smart card a memoria sincrona **Infineon
SLE4442** (e compatibili SLE4432 / SLE5532 / SLE5542) usando un lettore
**ACS ACR39U** su **Windows, Linux o macOS**, tramite Python + `pyscard`.

Legge:
- i **256 byte** di memoria principale,
- i **bit di protezione** dei primi 32 byte,
- il **contatore di errori** di presentazione del PSC.

---

## Perché i tentativi precedenti restituivano un buffer vuoto `[]`

Il rapporto tecnico iniziale usava il **canale di escape/IOCTL**
(`connection.control(IOCTL_CCID_ESCAPE, ...)`) e un payload proprietario
tipo `FF DE 00 00 01 02`. **È l'approccio sbagliato per l'ACR39U.** Due errori:

1. **Canale sbagliato.** I comandi per le memory card ACS sono
   *pseudo-APDU* e vanno inviati sul **canale dati PC/SC**
   (`connection.transmit()` / `SCardTransmit`), dopo un normale
   `SCardConnect`. Il canale `control()`/escape serve ad altro (configurazione
   del lettore), non a leggere la carta.

2. **Manca `SELECT_CARD_TYPE`.** Prima di qualsiasi lettura bisogna dire al
   firmware quale carta sta pilotando:

   ```
   FF A4 00 00 01 06        (0x06 = famiglia 2-wire SLE4432/SLE4442)
   ```

   Senza questo comando il firmware non attiva la gestione 2-wire e ogni
   `FF B0 ...` torna vuoto.

**Non serve nessun bit-banging di Clock/Data né alcuna escape proprietaria.**
Il firmware dell'ACR39U implementa già il protocollo sincrono a 2 fili: una
volta selezionato il tipo carta, pilota lui i segnali fisici. Si inviano solo
le pseudo-APDU standard ACS qui sotto.

---

## Set di comandi (ACR39 Series Reference Manual v1.05, par. 8.4)

| Operazione | Pseudo-APDU | Risposta |
|---|---|---|
| Seleziona tipo carta | `FF A4 00 00 01 06` | `90 00` |
| Leggi memoria | `FF B0 00 <addr> <len>` | `<dati…> 90 00` |
| Leggi contatore errori PSC | `FF B1 00 00 04` | `<EC> xx xx xx 90 00` |
| Leggi bit di protezione | `FF B2 00 00 04` | `<P1..P4> 90 00` |
| Scrivi memoria | `FF D0 00 <addr> <len> <dati…>` | `90 00` |
| Presenta PSC (sblocca scrittura) | `FF 20 00 00 03 <p1 p2 p3>` | `90 <EC>` |
| Cambia PSC | `FF D2 00 01 03 <p1 p2 p3>` | `90 00` |

Contatore errori (`EC`): `07` = ultima verifica corretta; `00` = carta
bloccata (tentativi esauriti); altri valori = verifica fallita.

Bit di protezione: `1` = byte scrivibile, `0` = byte protetto in scrittura
(irreversibile).

---

## Note sulla memoria di sicurezza e sul PSC

- La **memoria principale (256 byte) si legge senza PSC**. Per un semplice
  dump non serve nessun codice.
- Il **PSC (3 byte) non è mai leggibile in chiaro**: nell'area di sicurezza è
  mascherato. Serve solo per **abilitare la scrittura**.
- Lo script di default esegue **solo letture**. L'opzione `--psc` serve
  unicamente a *verificare* un PSC noto: non esegue alcuna scrittura.

---

## Uso

Requisito: Python 3 e la libreria `pyscard`.

```bash
pip install pyscard
```

Su Windows: doppio clic su **`LEGGI-SLE4442.cmd`** (nella cartella principale
del progetto), oppure da riga di comando:

```bash
python dump_sle4442.py                    # dump su schermo + file .bin
python dump_sle4442.py --out tessera.bin  # scegli il nome del file
python dump_sle4442.py --reader 0         # scegli il lettore per indice
python dump_sle4442.py --psc FFFFFF       # verifica un PSC noto (facoltativo)
```

Il dump della memoria principale viene salvato in `sle4442_dump.bin`
(o nel file indicato con `--out`).

---

## Risoluzione problemi

- **"nessun lettore PC/SC rilevato"** — su Windows controlla che il servizio
  *Smart Card* (SCardSvr) sia avviato e che l'ACR39U compaia in Gestione
  dispositivi.
- **`SELECT_CARD_TYPE` rifiutato** — la carta non è della famiglia 2-wire
  SLE4432/SLE4442, oppure non è inserita correttamente.
- **Risposte ancora vuote** — assicurati di usare `transmit()` e non
  `control()`: è proprio l'errore che questo script corregge.
