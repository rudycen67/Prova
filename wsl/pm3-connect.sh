#!/usr/bin/env bash
#
# pm3-connect.sh
# --------------
# Comodo wrapper per connettersi al Proxmark3: trova client e porta e apre
# la sessione interattiva pm3. Puoi passare comandi opzionali, es.:
#
#   ./pm3-connect.sh                 # sessione interattiva
#   ./pm3-connect.sh 'hw status'     # esegue un comando e chiude
#
set -uo pipefail

if command -v pm3 >/dev/null 2>&1; then
  PM3="pm3"
elif [ -x "$HOME/proxmark3/pm3" ]; then
  PM3="$HOME/proxmark3/pm3"
else
  echo "❌ Client pm3 non trovato. Esegui prima ./setup.sh" >&2
  exit 1
fi

PORT=""
for p in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
  [ -e "$p" ] && PORT="$p" && break
done

if [ -z "$PORT" ]; then
  echo "❌ Porta seriale non trovata. Collega il Proxmark3 e verifica l'attach a WSL" >&2
  echo "   (usbipd attach --wsl --hardware-id 9ac4:4b8f)." >&2
  exit 1
fi

echo "==> Connessione a $PORT ..."
if [ "$#" -gt 0 ]; then
  exec "$PM3" -p "$PORT" -c "$*"
else
  exec "$PM3" -p "$PORT"
fi
