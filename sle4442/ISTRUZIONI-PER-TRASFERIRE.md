# ISTRUZIONI PER TRASFERIRE UNA CONVERSAZIONE A UN'ALTRA INTELLIGENZA
# (prompt riutilizzabile — copia e incolla all'IA che deve preparare il passaggio)

Devi preparare un PASSAGGIO DI CONSEGNE COMPLETO di questa conversazione e del
lavoro svolto, in modo che un'altra intelligenza artificiale possa riprendere
esattamente da dove siamo, senza che io debba rispiegare nulla. Segui queste
regole alla lettera.

## OBIETTIVO
Trasferire TUTTO: nessun punto escluso. Non riassumere in modo che si perdano
dettagli: ogni nozione, numero, link, comando, decisione e spiegazione deve
sopravvivere al passaggio. L'altra IA deve poter continuare come se avesse
vissuto l'intera conversazione.

## REGOLA ASSOLUTA: TUTTO IL CONTENUTO DELLA CHAT
Trasferisci TUTTO il contenuto che appartiene a questa chat, dall'inizio alla
fine, senza eccezioni: ogni mia domanda e ogni tua risposta, ogni spiegazione
anche ripetuta o rivista, ogni esempio, ogni link, ogni prezzo, ogni numero,
ogni comando, ogni file, ogni disegno, ogni decisione, ogni vicolo cieco e il
motivo per cui e' stato scartato, ogni correzione fatta in corsa, ogni
preferenza che ho espresso e ogni volta che mi sono lamentato di qualcosa.
Niente viene considerato "superfluo" o "gia' detto": se e' stato scritto in
chat, deve finire nel passaggio di consegne. In caso di dubbio, includi.
L'altra IA deve poter ricostruire l'INTERA chat dai documenti, non una sintesi.

## COSA DEVI PRODURRE (tre cose)
1. Un documento "passaggio di consegne" (es. TRASFERIMENTO.md) con il quadro
   completo e strutturato.
2. Un documento "dettagli completi" (es. DETTAGLI.md) che riscrive OGNI
   argomento PER ESTESO, parola per parola, non riassunto.
3. Un pacchetto ZIP con i due documenti + TUTTI i file di lavoro prodotti
   (codice, guide, disegni), piu' un breve LEGGIMI che spiega come usarlo.
Inviami i file scaricabili e, se esiste un repository, committali anche li'.

## COSA DEVE CONTENERE IL DOCUMENTO "PASSAGGIO DI CONSEGNE"
- NOME e ARGOMENTO esatti della conversazione.
- CHI SONO IO e come trattarmi: lingua, preferenze, cose da NON fare (es. frasi
  che trovo fastidiose), modo di rispondere che preferisco, eventuali limiti
  (es. daltonismo -> disegni leggibili senza affidarsi al colore).
- PROBLEMA ORIGINALE e SOLUZIONE trovata.
- TUTTE le NOZIONI TECNICHE accertate (tabelle di comandi, strutture, valori).
- STATO DEL LAVORO: cosa funziona, cosa no, fatti verificati (con i numeri reali).
- ELENCO di TUTTI i FILE prodotti, con una riga di descrizione ciascuno, e dove
  stanno (repository + branch).
- CATALOGO COMPLETO di ogni PRODOTTO, LINK e PREZZO citato nella conversazione.
- DATI TECNICI REALI (output, codici, misure, dump, identificativi).
- TUTTI i COMANDI usati (API, shell, strumenti).
- FLUSSO CRONOLOGICO della conversazione: ogni tappa/domanda e cosa si e' deciso.
- ELENCO dei DIAGRAMMI/allegati con cosa mostrano.
- PROSSIMI PASSI aperti: da dove ripartire.
- ISTRUZIONI OPERATIVE per l'altra IA (regole di comportamento, dove trovare i
  file, eventuali regole di attribuzione/commit).

## COSA DEVE CONTENERE IL DOCUMENTO "DETTAGLI COMPLETI"
Un capitolo per ogni argomento affrontato, scritto PER ESTESO come e' stato
spiegato: definizioni, il "perche'", gli esempi con i numeri, le eccezioni, i
limiti onesti. Non scrivere "come gia' detto": riscrivi la spiegazione intera.
Se un concetto e' stato spiegato con un esempio numerico, riportalo per intero.

## PRINCIPI DA RISPETTARE
- Esaustivita' sopra la brevita': se sei in dubbio se includere qualcosa, includilo.
- Fedelta': riporta i valori e i link ESATTI, non approssimati.
- Onesta': scrivi anche cosa NON ha funzionato, i vicoli ciechi e perche', e i
  limiti reali (cosa non e' fattibile e perche').
- Nessun gergo inventato internamente dato per scontato: spiega le sigle.
- Struttura chiara con titoli, cosi' l'altra IA trova subito cio' che serve.

## CONSEGNA
- Crea i file, mettili in un pacchetto ZIP, e consegnameli scaricabili.
- Se c'e' un repository di lavoro, committa li' i documenti (cosi' restano la
  fonte ufficiale aggiornata) e dimmi branch e percorso.
- Dammi la FRASE ESATTA da scrivere all'altra IA per farle riprendere il lavoro
  (es. "Leggi TRASFERIMENTO.md e DETTAGLI.md e continua da li'").

## VERIFICA FINALE (fai questo prima di consegnare)
Rileggi la conversazione dall'inizio e controlla, punto per punto, che nei
documenti non manchi: nessun link, nessun prezzo, nessun comando, nessun numero,
nessuna decisione, nessun file, nessuna spiegazione. Se trovi un buco, colmalo.
