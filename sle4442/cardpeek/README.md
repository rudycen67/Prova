# Leggere la SLE4442 con Cardpeek

Script Lua per leggere una smart card **SLE4442** dall'interfaccia grafica
**Cardpeek**, in alternativa agli script Python del progetto.

File: [`sle4442.lua`](sle4442.lua)

## Perche' serve questo script

Cardpeek "di serie" **non** legge la SLE4442: i suoi script predefiniti
coprono solo carte a microprocessore (EMV, SIM, passaporti, Calypso...) e non
inviano i comandi ACS per le memory card sincrone a 2 fili. Questo e'
esattamente il motivo del fallimento iniziale.

Cardpeek pero' puo' inviare **qualsiasi** APDU via Lua con `card.send()`.
Questo script manda le stesse pseudo-APDU ACS del tool Python
(`SELECT_CARD_TYPE` + letture), quindi funziona dove gli script di serie no.

## Installazione

1. Copia `sle4442.lua` nella cartella degli script utente di Cardpeek.
   Su Windows di solito e':

   ```
   %APPDATA%\cardpeek\scripts\
   ```

   Se non la trovi, apri Cardpeek, scheda **logs**: stampa i percorsi che usa.
2. Riavvia Cardpeek (o ricarica gli script).

## Uso

1. Inserisci la carta **SLE4442** nel lettore **ACR39U**.
2. Premi **Analyzer** e scegli **"SLE 4442 (memory card)"** dalla lista
   (oppure carica direttamente il file `sle4442.lua`).
3. Nell'albero vedrai:
   - **ATR**
   - **Memoria principale (256 byte)**, a blocchi di 16 byte
   - **Bit di protezione** (primi 32 byte)
   - **Contatore errori PSC + area sicurezza**
4. Con **Save** esporti l'analisi.

## Note

- Lo script fa **solo letture** e non richiede il PSC (la lettura non lo usa).
- L'API Lua di Cardpeek puo' variare un po' tra le versioni; lo script e'
  pensato per quelle recenti. Se un comando cambia nome, la scheda **logs** di
  Cardpeek aiuta a capire cosa adattare.
- Per scrivere/clonare usa gli script del progetto (`CLONA-SLE4442.cmd`):
  Cardpeek qui e' usato per leggere/ispezionare.
