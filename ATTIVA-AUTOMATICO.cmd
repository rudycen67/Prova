@echo off
REM ============================================================
REM  Proxmark3 -> Ubuntu/WSL : rendi tutto AUTOMATICO
REM  Fai doppio clic su questo file.
REM  Requisiti: connessione USB->WSL gia' funzionante (device
REM  gia' visto una volta in Ubuntu). Ti verranno chiesti solo
REM  il consenso UAC e la password sudo di Ubuntu.
REM ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\attiva-automatico.ps1"
