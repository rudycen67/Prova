@echo off
REM ============================================================
REM  Sintesi vocale Coqui TTS + RVC (dentro Ubuntu/WSL2)
REM  Fai doppio clic su questo file.
REM  - La PRIMA volta installa tutto (serve la password sudo di Ubuntu
REM    e parecchio tempo: vengono scaricati diversi GB).
REM  - Poi avvia il server su http://localhost:8000
REM  Per generare l'audio: voce\genera-voce.py (vedi docs\sintesi-vocale.md)
REM ============================================================
wsl --cd "%~dp0" -e bash voce/avvia-server.sh
pause
