# Changelog

## 2.1.1

- `/protect/status.xml` servito con `Content-Type: text/xml`, cosi' il
  sensore `rest` di Home Assistant lo legge come JSON senza altri passaggi.
- Esempio di configurazione Home Assistant: `docs/home-assistant-marss.yaml`.

## 2.1.0

- **nginx davanti a socat**: il modulo Marss regge una sola connessione SSLv3
  alla volta, mentre i browser ne aprono sei insieme e lo bloccavano
  ("Operation timed out"). Ora nginx accoda le richieste e socat
  (`max-children=1`) apre verso il modulo una connessione breve per richiesta.
- Link assoluti del modulo riscritti attraverso il ponte (`sub_filter`).
- Timeout di connessione (20 s) sul lato modulo.

## 2.0.1

- Porta predefinita del modulo: **443** (pagina web del Marss IP Controller).
  Verificato sul campo: la 26501 e' il protocollo dell'app, non HTTP.
- Etichette delle opzioni aggiornate.

## 2.0.0

- Supporto **SSLv3**: il modulo IP dell'antifurto (Marss IP Controller) parla
  solo SSLv3 con cifrari RC4, rifiutato da tutti i browser e sistemi moderni.
  L'add-on compila un OpenSSL 1.1.1w con SSLv3 riabilitato e un socat dedicato,
  e offre la pagina web del modulo in **HTTP semplice** su
  `http://<IP Home Assistant>:26501`.
- Nuova opzione `tls_mode` (ssl3 / tls1 / tls_auto / none). `none` equivale al
  comportamento della versione 1.x (inoltro TCP trasparente).
- L'installazione/aggiornamento compila OpenSSL sul dispositivo: su Raspberry
  Pi 3 richiede 15-30 minuti.

## 1.0.0

- Prima versione: proxy TCP `socat` verso la centrale Bentel Kyo.
- Indirizzo e porta della centrale configurabili dalla GUI.
- Immagine base `ghcr.io/home-assistant/base:3.24` dichiarata nel Dockerfile
  (compatibile con Supervisor >= 2026.04, che non passa piu' `BUILD_FROM`).
