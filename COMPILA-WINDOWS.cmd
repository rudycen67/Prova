@echo off
title Compila client Proxmark3 (Windows)
REM ============================================================
REM  Apre la shell di ProxSpace e ti mostra il comando (UNO) da
REM  incollare per compilare il client Proxmark3.
REM  (Le versioni di ProxSpace gestiscono i comandi automatici in
REM   modo diverso, quindi qui apriamo la shell e incolli tu 1 riga:
REM   e' il metodo affidabile su tutte le versioni.)
REM  Requisiti: ProxSpace estratto in C:\ProxSpace.
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

echo ================================================================
echo  Sto per aprire la shell di ProxSpace (prompt  [PS] ^> ).
echo.
echo  Quando si apre, INCOLLA questa UNICA riga e premi Invio:
echo.
echo      bash /c/Proxmark3-WSL/windows/build-in-proxspace.sh
echo.
echo  (se hai estratto il progetto altrove, adatta il percorso; in
echo   ProxSpace il disco C: si trova sotto /c/)
echo.
echo  In alternativa incolla i comandi manuali di docs\windows-nativo.md
echo ================================================================
echo.
pause
cd /d "%PSDIR%"
call "%PSDIR%\runme64.bat"
