# Changelog

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
