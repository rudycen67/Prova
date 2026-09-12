#!/usr/bin/env bash
#
# build-in-proxspace.sh
# ---------------------
# Da eseguire DENTRO la shell di ProxSpace (aperta con runme64.bat).
# Compila in un colpo solo il client Proxmark3 per Windows, allineato al
# firmware del device (commit 72b1b17a3, RDV4).
#
# Uso, dentro la shell ProxSpace (prompt [PS] >):
#     bash /c/Proxmark3-WSL/windows/build-in-proxspace.sh
# (adatta il percorso a dove hai messo la cartella del progetto; in ProxSpace
#  il disco C: si trova sotto /c/)
#
set -e

PLATFORM="${PLATFORM:-PM3RDV4}"
COMMIT="${COMMIT:-72b1b17a3}"

echo "==> Vado nella cartella sorgenti di ProxSpace (/pm3)..."
cd /pm3

if [ -d proxmark3/.git ]; then
  echo "==> Sorgente gia' presente: aggiorno..."
  cd proxmark3
  git fetch --all --tags --quiet || true
else
  echo "==> Scarico il sorgente (RRG/Iceman)..."
  git clone https://github.com/RfidResearchGroup/proxmark3.git
  cd proxmark3
fi

echo "==> Mi allineo al firmware (commit $COMMIT)..."
git checkout "$COMMIT" 2>/dev/null || echo "   (commit non trovato, resto sull'ultima versione)"

echo "==> Compilo il client (PLATFORM=$PLATFORM). Puo' richiedere ~15-20 min..."
make clean
make -j"$(nproc)" PLATFORM="$PLATFORM" client

echo
echo "=============================================================="
echo " CLIENT COMPILATO."
echo " Ora, con il Proxmark3 collegato:"
echo "   - fai doppio clic su APRI-PROXMARK3.cmd  (apre pm3 gia' connesso), oppure"
echo "   - qui nella shell:   ./pm3    (rileva la porta da solo)"
echo "=============================================================="
