@echo off
title Proxmark3
REM ============================================================
REM  APRI-PROXMARK3 : apre il client Proxmark3 GIA' CONNESSO.
REM  Doppio clic per usare il Proxmark3 in Windows senza digitare
REM  nessun comando di connessione (la porta viene rilevata da sola).
REM
REM  Requisiti (una volta sola):
REM   - ProxSpace installato in C:\ProxSpace
REM   - client compilato (vedi docs/windows-nativo.md)
REM   - Proxmark3 collegato alla USB (in Windows, non inoltrato a WSL)
REM ============================================================

REM --- Dove hai installato ProxSpace (cambia qui se diverso) ---
set "PSDIR=C:\ProxSpace"

if not exist "%PSDIR%\runme64.bat" (
  echo [X] ProxSpace non trovato in "%PSDIR%".
  echo     Se l'hai messo altrove, apri questo file col Blocco note e
  echo     modifica la riga:   set "PSDIR=C:\ProxSpace"
  echo.
  pause
  exit /b 1
)

echo Avvio del Proxmark3... (rilevo la porta da solo)
cd /d "%PSDIR%"

REM Avvia l'ambiente ProxSpace ed esegue il client pm3 (auto-rileva la porta).
REM Se il tuo ProxSpace ha i sorgenti in un percorso diverso, cambia /pm3/proxmark3.
call "%PSDIR%\runme64.bat" bash -lc "cd /pm3/proxmark3 && ./pm3"

echo.
echo (sessione Proxmark3 terminata)
pause
