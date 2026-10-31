@echo off
setlocal
REM Programma con interfaccia grafica per leggere e scrivere la SLE4442.
REM Richiede Python 3 e pyscard (pip install pyscard).
cd /d "%~dp0sle4442"

where python >nul 2>nul
if errorlevel 1 (
  echo [ERRORE] Python non trovato nel PATH. Installa Python 3 da python.org
  echo e spunta "Add Python to PATH".
  pause
  exit /b 1
)

python -c "import smartcard" >nul 2>nul
if errorlevel 1 (
  echo [INFO] Installo la libreria pyscard...
  python -m pip install pyscard
)

start "" pythonw sle4442_gui.py
