# Sniffing didattico della SLE4442 — vedere il PSC in chiaro

Guida passo-passo per **osservare** il protocollo 2-wire della SLE4442 con un
logic analyzer economico e PulseView, e riconoscere la password (PSC) che
transita in chiaro sul filo.

> Scopo **didattico**, sulla **tua** carta e il **tuo** lettore: catturi una
> scrittura che generi tu stesso (con `CLONA-SLE4442` o `dump --psc FFFFFF`),
> non intercetti nessuno. Intercetta solo carte/lettori tuoi o autorizzati.

---

## 1. Perché funziona

La SLE4442 non cifra nulla. Per verificare il PSC, il lettore deve **inviarlo**
alla carta sul filo dati (I/O) come bit normali. Chi ascolta quel filo li legge
tali e quali. Noi genereremo la scrittura noi stessi (PSC `FFFFFF` sulla carta
clone) e la "spieremo" per vederla comparire.

---

## 2. Materiale

- Il tuo **ACR39U** + PC (già pronti).
- Una **SLE4442** (va bene la carta clone, PSC `FFFFFF`).
- Un **prolunga/extender per smart card** che esponga i contatti su pin: la
  carta va nell'extender, l'extender nel lettore, e dai pin agganci le sonde.
  (Cerca `smart card extender` / `ISO7816 extension`. Senza di esso i contatti
  dell'ACR39U sono interni e non raggiungibili.)
- Un **logic analyzer USB** economico (8 canali, 24 MHz, ~10 €) con i cavetti.
- **PulseView** (sigrok) installato: https://sigrok.org/wiki/Downloads

---

## 3. I contatti ISO-7816 della SLE4442

Degli 8 contatti ne servono tre (più alimentazione/reset che restano al
lettore):

| Contatto | Segnale | Al logic analyzer |
|---|---|---|
| **C3** | CLK (clock) | canale **D0** |
| **C7** | I/O (dato) | canale **D1** |
| **C5** | GND (massa) | **GND** |
| C1 | VCC | (resta al lettore) |
| C2 | RST | (resta al lettore) |

Schema:

```
  Carta ──▶ Extender ──▶ ACR39U ──USB──▶ PC (lancia CLONA/dump)
               │  │  │
              C3 C7 C5
               │  │  │
              D0 D1 GND
               ▼  ▼  ▼
          Logic analyzer ──USB──▶ PulseView
          (ascolta in parallelo, non disturba)
```

---

## 4. Preparazione software (Windows)

1. Installa **PulseView**.
2. Collega il logic analyzer via USB. Su Windows assegnagli il driver
   **WinUSB** con **Zadig** (https://zadig.akeo.ie): *Options → List All
   Devices*, seleziona il dispositivo, driver **WinUSB**, *Install Driver*.

---

## 5. Collegamento

1. Inserisci la carta nell'extender e l'extender nel lettore ACR39U.
2. Collega i cavetti: **C3→D0**, **C7→D1**, **C5→GND** dell'analizzatore.
3. Collega il logic analyzer al PC via USB.

---

## 6. Impostazioni di cattura in PulseView

1. In alto a sinistra scegli il driver **fx2lafw** → *Scan*.
2. **Sample rate**: **4 MHz** (il bus della carta è lento, qui sei abbondante).
3. **Numero di campioni**: alto, es. **8-16 M**, così copri qualche secondo.
4. Aggiungi il decoder: icona decoder → cerca **SLE44xx** → assegnalo con
   *Clock* = **D0**, *Data* = **D1**.

Suggerimento trigger (facoltativo): imposta un trigger sul **fronte di discesa
di D1** per far partire la cattura quando inizia l'attività. Oppure lascia
libero e avvia a mano.

---

## 7. La cattura

1. In PulseView premi **Run** (inizia a registrare).
2. Subito dopo, sul PC lancia la scrittura che genera il PSC:

   ```bat
   python dump_sle4442.py --psc FFFFFF
   ```

   (oppure `CLONA-SLE4442.cmd`). Questo fa inviare al lettore il comando
   PRESENT_CODE con `FF FF FF`.
3. Quando l'operazione finisce, **Stop** in PulseView.

---

## 8. Cosa cercare nel tracciato

Zoomando sui segnali (rotellina del mouse), impari a riconoscere:

1. **Il ritmo**: `CLK` (D0) a impulsi regolari; `I/O` (D1) che cambia tra un
   impulso e l'altro.
2. **START**: `I/O` che **scende mentre `CLK` è alto** → inizio di un messaggio.
3. **STOP**: `I/O` che **sale mentre `CLK` è alto** → fine messaggio.
4. **I byte**: 8 impulsi di clock per byte; il dato vale quando `CLK` è alto.
5. **La riga del decoder SLE44xx**: traduce tutto in comandi leggibili. Cerca
   il comando di **confronto codice (Compare Verification Data / Present Code)**:
   lì, nel campo dati, compaiono i **3 byte del PSC**: `FF FF FF`.

Se hai usato un PSC diverso, vedresti quei byte al posto di `FF FF FF`. È la
dimostrazione che la password **viaggia in chiaro**.

---

## 9. Lettura "a mano" (per capire davvero)

Per convincerti che il decoder non "bara", prova a leggere un byte da solo:

1. Trova uno START.
2. Conta 8 impulsi di `CLK`; per ciascuno segna il livello di `I/O` quando
   `CLK` è alto.
3. Hai 8 bit. Ricordati che è **LSB-first**: il **primo** bit è il bit 0.
   Riordina e converti in esadecimale.
4. Confronta con quanto dice il decoder: devono coincidere.

---

## 10. La morale

Una carta con crittografia (es. MIFARE DESFire) non manda mai la chiave sul
filo: fa un botta-e-risposta matematico e la chiave resta nel chip. La SLE4442
non può: il suo unico modo di verificare il PSC è **riceverlo** e confrontarlo
dentro. Per riceverlo, deve farlo transitare sul filo. La "debolezza" non è un
bug: è il **principio** di una carta senza crittografia.

---

## 11. Risoluzione problemi

- **PulseView non vede l'analizzatore (Windows)**: rifai il driver con Zadig
  (WinUSB).
- **Tracciato piatto / nessun segnale**: controlla C3/C7/C5 e che la massa sia
  in comune; verifica che l'extender faccia contatto.
- **Il decoder non compare**: aggiorna PulseView; il decoder si chiama
  `SLE44xx`.
- **Non trovi il PSC**: assicurati di aver lanciato un comando che **scrive**
  (`--psc` o `CLONA`). Una semplice lettura non manda mai il PSC.
