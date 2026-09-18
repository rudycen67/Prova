@echo off
title Crea podcast
REM ============================================================
REM  CREA-PODCAST : trasforma un copione di testo in un episodio MP3
REM  con voci neurali italiane.
REM
REM  Doppio clic su questo file, poi trascina dentro alla finestra
REM  il copione (.md o .txt) e premi Invio.
REM
REM  Requisiti (una volta sola):
REM   - Python 3 installato da python.org (spunta "Add to PATH")
REM   - la libreria delle voci:  pip install edge-tts
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

python "%~dp0crea-podcast.py" "%COPIONE%"
echo.
pause
