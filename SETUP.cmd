@echo off
REM ============================================================
REM  Proxmark3 su WSL2 - CONFIGURAZIONE COMPLETA
REM  Fai doppio clic su questo file.
REM  Requisiti: Windows 10/11 con WSL2 + Ubuntu, Proxmark3 collegato.
REM  Ti verranno chiesti solo: il consenso UAC e la password sudo di Ubuntu.
REM ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\setup-completo.ps1"
