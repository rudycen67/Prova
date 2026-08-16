#!/usr/bin/env bash
#
# auto-seriale.sh
# ---------------
# Rende /dev/ttyACM* disponibile AUTOMATICAMENTE in WSL ad ogni avvio, così
# che appena il Proxmark3 viene agganciato compaia subito come /dev/ttyACM0.
#
# Fa due cose (una tantum):
#   1) aggiunge l'utente al gruppo 'dialout' (accesso alle porte seriali);
#   2) configura /etc/wsl.conf per caricare il modulo 'cdc_acm' ad ogni boot
#      di WSL (senza dover fare 'sudo modprobe cdc_acm' ogni volta).
#
# Dopo l'esecuzione, riavvia WSL una volta:  (PowerShell)  wsl --shutdown
#
set -uo pipefail

echo "==> Aggiungo $USER al gruppo dialout..."
sudo usermod -aG dialout "$USER" || true

echo "==> Configuro /etc/wsl.conf per caricare cdc_acm ad ogni avvio di WSL..."
sudo bash <<'ROOT'
set -e
CONF=/etc/wsl.conf
touch "$CONF"
if grep -q 'modprobe cdc_acm' "$CONF"; then
  echo "   gia' configurato."
elif grep -q '^\[boot\]' "$CONF"; then
  if grep -qE '^[[:space:]]*command[[:space:]]*=' "$CONF"; then
    # esiste gia' un command al boot: accodo cdc_acm mantenendo quello esistente
    sed -i -E 's#^([[:space:]]*command[[:space:]]*=[[:space:]]*)(.*)$#\1\2 ; modprobe cdc_acm#' "$CONF"
  else
    sed -i '/^\[boot\]/a command = modprobe cdc_acm' "$CONF"
  fi
  echo "   aggiornata sezione [boot]."
else
  printf '\n[boot]\ncommand = modprobe cdc_acm\n' >> "$CONF"
  echo "   aggiunta sezione [boot]."
fi
ROOT

echo "==> Carico subito il modulo (per usarlo gia' adesso)..."
sudo modprobe cdc_acm || true

echo
echo "=============================================================="
echo " Fatto. Applica con un riavvio di WSL (da PowerShell):"
echo "     wsl --shutdown"
echo
echo " Da allora cdc_acm sara' caricato ad ogni avvio: appena il"
echo " Proxmark3 e' agganciato a WSL, comparira' come /dev/ttyACM0"
echo " senza altri comandi."
echo "=============================================================="
