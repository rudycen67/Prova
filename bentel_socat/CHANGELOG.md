# Changelog

## 1.0.0

- Prima versione: proxy TCP `socat` verso la centrale Bentel Kyo.
- Indirizzo e porta della centrale configurabili dalla GUI.
- Immagine base `ghcr.io/home-assistant/base:3.24` dichiarata nel Dockerfile
  (compatibile con Supervisor >= 2026.04, che non passa piu' `BUILD_FROM`).
