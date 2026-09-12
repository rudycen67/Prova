@echo off
title Compila client Proxmark3 (Windows)
REM ============================================================
REM  Compila il client Proxmark3 per Windows in un doppio clic.
REM  Requisiti: ProxSpace estratto in C:\ProxSpace.
REM  (Se ProxSpace e' altrove, cambia la riga PSDIR qui sotto.)
REM  Dura ~15-20 min. Una volta sola.
REM ============================================================

set "PSDIR=C:\ProxSpace"

if not exist "%PSDIR%\runme64.bat" (
  echo [X] ProxSpace non trovato in "%PSDIR%".
  echo     Scarica ProxSpace da https://github.com/Gator96100/ProxSpace/releases
  echo     ed estrailo in C:\ProxSpace ^(percorso senza spazi^).
  echo     Se l'hai messo altrove, apri questo file col Blocco note e cambia PSDIR.
  echo.
  pause
  exit /b 1
)

echo Avvio la compilazione dentro ProxSpace...
echo (se questa finestra si chiude subito senza compilare, usa il metodo manuale
echo  indicato in docs\windows-nativo.md)
echo.

call "%PSDIR%\runme64.bat" bash -lc "cd /pm3 && { [ -d proxmark3/.git ] && (cd proxmark3 && git fetch --all --tags) || git clone https://github.com/RfidResearchGroup/proxmark3.git; } ; cd /pm3/proxmark3 && (git checkout 72b1b17a3 || true) && make clean && make -j$(nproc) PLATFORM=PM3RDV4 client && echo COMPILAZIONE_OK"

echo.
echo Se sopra vedi COMPILAZIONE_OK, il client e' pronto: usa APRI-PROXMARK3.cmd
pause
