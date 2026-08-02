#!/usr/bin/env bash
#
# setup.sh
# --------
# Installa le dipendenze e compila il client Proxmark3 (fork Iceman/RRG) su
# Ubuntu dentro WSL2. Da eseguire UNA SOLA VOLTA (o quando vuoi aggiornare).
#
# Uso:
#   ./setup.sh                     # build generica (PM3 Easy, cloni, EVO...)
#   PLATFORM=PM3RDV4 ./setup.sh    # per il Proxmark3 RDV4
#
set -euo pipefail

PROXMARK_DIR="${PROXMARK_DIR:-$HOME/proxmark3}"
PLATFORM="${PLATFORM:-PM3GENERIC}"   # PM3RDV4 per l'RDV4, PM3GENERIC per gli altri

echo "==> Piattaforma di build: $PLATFORM"
echo "==> Directory sorgenti  : $PROXMARK_DIR"
echo

echo "==> Aggiorno l'indice dei pacchetti..."
sudo apt update

echo "==> Installo le dipendenze di build..."
sudo apt install -y --no-install-recommends \
  git ca-certificates build-essential pkg-config \
  libreadline-dev gcc-arm-none-eabi libnewlib-dev \
  qtbase5-dev libbz2-dev libbluetooth-dev \
  libpython3-dev libssl-dev libgd-dev usbutils

echo "==> Aggiungo l'utente '$USER' al gruppo 'dialout' (accesso alle porte seriali)..."
sudo usermod -aG dialout "$USER" || true

echo "==> Carico il modulo cdc_acm (se non gia' presente nel kernel WSL)..."
sudo modprobe cdc_acm 2>/dev/null || true

echo "==> Scarico/aggiorno il sorgente del client Proxmark3 (Iceman/RRG)..."
if [ -d "$PROXMARK_DIR/.git" ]; then
  git -C "$PROXMARK_DIR" pull --ff-only || echo "   (pull saltato: modifiche locali presenti)"
else
  git clone https://github.com/RfidResearchGroup/proxmark3.git "$PROXMARK_DIR"
fi

echo "==> Compilo il client (PLATFORM=$PLATFORM). Puo' richiedere qualche minuto..."
cd "$PROXMARK_DIR"
make clean
make -j"$(nproc)" PLATFORM="$PLATFORM"

echo "==> Installo il client nel sistema (/usr/local/bin/pm3)..."
sudo make install PLATFORM="$PLATFORM"

echo
echo "=============================================================="
echo " Setup completato."
echo
echo " IMPORTANTE: chiudi e riapri WSL affinche' il gruppo 'dialout'"
echo " diventi effettivo. Da PowerShell:   wsl --shutdown"
echo
echo " Poi verifica il firmware del dispositivo con:"
echo "     ./check-firmware.sh"
echo " e connettiti con:"
echo "     pm3"
echo "=============================================================="
