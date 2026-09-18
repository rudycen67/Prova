@echo off
title Crea podcast
REM ============================================================
REM  CREA-PODCAST : trasforma un copione di testo in un episodio
REM  audio con voci neurali.
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
echo   [1] Voci gratuite          nessuna chiave, buona qualita'   ^<-- predefinito
echo   [2] Voci Google            piu' espressive, si dirigono a parole
echo   [3] Voci ElevenLabs        massimo realismo
echo.
set "SCELTA="
set /p "SCELTA=Scegli e premi Invio [1]: "

if "%SCELTA%"=="2" goto :google
if "%SCELTA%"=="3" goto :eleven

python "%~dp0crea-podcast.py" "%COPIONE%"
goto :fine


:google
if exist "%~dp0chiave-google.txt" goto :google_vai
echo.
echo Serve una chiave Google, gratuita. Si prende cosi':
echo   1. vai su https://aistudio.google.com/apikey e accedi col tuo account Google
echo   2. clicca "Create API key"
echo   3. copia la chiave e incollala qui sotto
echo      ^(per incollare: tasto destro dentro questa finestra^)
echo.
set "CHIAVE="
set /p "CHIAVE=Chiave: "
if "%CHIAVE%"=="" goto :senzachiave
> "%~dp0chiave-google.txt" echo %CHIAVE%
echo.
echo [i] Chiave salvata in chiave-google.txt ^(resta sul tuo computer^).
:google_vai
python "%~dp0crea-podcast.py" "%COPIONE%" -m google
goto :fine


:eleven
if exist "%~dp0chiave-elevenlabs.txt" goto :eleven_vai
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
echo [i] Chiave salvata in chiave-elevenlabs.txt ^(resta sul tuo computer^).
:eleven_vai
python "%~dp0crea-podcast.py" "%COPIONE%" -m elevenlabs
goto :fine


:fine
echo.
pause
exit /b 0

:senzachiave
echo [X] Nessuna chiave inserita.
echo.
pause
exit /b 1
