@echo off
title Crea podcast
REM ============================================================
REM  CREA-PODCAST : trasforma un copione di testo in un episodio MP3
REM  con voci neurali.
REM
REM  Doppio clic su questo file, poi trascina dentro alla finestra
REM  il copione (.md o .txt) e premi Invio.
REM
REM  Requisiti (una volta sola):
REM   - Python 3 installato da python.org (spunta "Add to PATH")
REM   - la libreria delle voci: la installa da solo al primo avvio
REM ============================================================
setlocal

where python >nul 2>&1
if errorlevel 1 (
  echo [X] Python non trovato.
  echo     Installalo da https://www.python.org/downloads/
  echo     ricordandoti di spuntare "Add Python to PATH".
  echo.
  pause
  exit /b 1
)

python -c "import edge_tts" >nul 2>&1
if errorlevel 1 (
  echo [i] Installo le voci ^(edge-tts^)...
  python -m pip install --quiet --upgrade edge-tts
  if errorlevel 1 (
    echo [X] Installazione fallita. Prova a mano:  pip install edge-tts
    echo.
    pause
    exit /b 1
  )
)

REM --- Quale copione ---
set "COPIONE=%~1"
if "%COPIONE%"=="" (
  echo.
  echo Trascina qui il file del copione e premi Invio
  echo ^(oppure scrivi il percorso^):
  set /p "COPIONE=> "
)

REM Toglie le virgolette che Windows aggiunge quando trascini un file.
set "COPIONE=%COPIONE:"=%"

if not exist "%COPIONE%" (
  echo [X] File non trovato: "%COPIONE%"
  echo.
  pause
  exit /b 1
)

REM --- Quali voci ---
echo.
echo   [1] Voci gratuite ^(nessuna chiave, buona qualita'^)   ^<-- predefinito
echo   [2] Voci ElevenLabs ^(massimo realismo, serve un account^)
echo.
set "SCELTA="
set /p "SCELTA=Scegli e premi Invio [1]: "

if not "%SCELTA%"=="2" (
  python "%~dp0crea-podcast.py" "%COPIONE%"
  echo.
  pause
  exit /b 0
)

REM --- ElevenLabs: la chiave si chiede una volta sola ---
if exist "%~dp0chiave-elevenlabs.txt" goto :genera

echo.
echo Serve la tua chiave personale ElevenLabs. Si prende cosi':
echo   1. vai su https://elevenlabs.io e accedi ^(il piano gratuito basta^)
echo   2. clicca l'icona del profilo in alto a destra, poi "API keys"
echo   3. copia la chiave e incollala qui sotto
echo      ^(per incollare: tasto destro dentro questa finestra^)
echo.
set "CHIAVE="
set /p "CHIAVE=Chiave: "
if "%CHIAVE%"=="" goto :senzachiave

> "%~dp0chiave-elevenlabs.txt" echo %CHIAVE%
echo.
echo [i] Chiave salvata in chiave-elevenlabs.txt
echo     Resta sul tuo computer e non viene caricata su GitHub.
echo     Non te la chiedo piu': per cambiarla, cancella quel file.

:genera
python "%~dp0crea-podcast.py" "%COPIONE%" -m elevenlabs
echo.
pause
exit /b 0

:senzachiave
echo [X] Nessuna chiave inserita.
echo.
pause
exit /b 1
