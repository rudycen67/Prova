@echo off
setlocal
REM Launcher Windows: clona un dump su una carta SLE4442 VERGINE con ACR39U.
REM Clona SOLO tessere tue o autorizzate. Richiede Python 3 e pyscard.
cd /d "%~dp0sle4442"

where python >nul 2>nul
if errorlevel 1 (
  echo [ERRORE] Python non trovato nel PATH. Installa Python 3 da python.org
  pause
  exit /b 1
)

python -c "import smartcard" >nul 2>nul
if errorlevel 1 (
  echo [INFO] Installo la libreria pyscard...
  python -m pip install pyscard
)

set DUMP=sle4442_dump.bin
if not "%~1"=="" set DUMP=%~1
if not exist "%DUMP%" (
  echo [ERRORE] File dump non trovato: %DUMP%
  echo Prima esegui LEGGI-SLE4442.cmd per creare sle4442_dump.bin
  pause
  exit /b 1
)

set /p PSC=PSC della carta VERGINE di destinazione (6 cifre hex, Invio per FFFFFF): 
if "%PSC%"=="" set PSC=FFFFFF

echo.
echo Inserisci la carta VERGINE di destinazione nel lettore, poi premi un tasto.
pause >nul
python clona_sle4442.py "%DUMP%" --psc %PSC%

echo.
pause
