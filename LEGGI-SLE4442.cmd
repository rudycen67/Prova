@echo off
setlocal
REM Launcher Windows: dump di una smart card SLE4442 con lettore ACS ACR39U.
REM Richiede Python 3 e pyscard (pip install pyscard).
cd /d "%~dp0sle4442"

where python >nul 2>nul
if errorlevel 1 (
  echo [ERRORE] Python non trovato nel PATH. Installa Python 3 da python.org
  echo e assicurati di spuntare "Add Python to PATH".
  pause
  exit /b 1
)

python -c "import smartcard" >nul 2>nul
if errorlevel 1 (
  echo [INFO] Installo la libreria pyscard...
  python -m pip install pyscard
)

echo.
echo Inserisci la carta SLE4442 nel lettore ACR39U, poi premi un tasto.
pause >nul
python dump_sle4442.py %*

echo.
pause
