#!/usr/bin/env bash
#
# aggiungi-voce.sh
# ----------------
# Copia un modello RVC v2 (.pth + .index) nella struttura attesa dal server:
#
#   models/<nome>/<nome>.pth
#   models/<nome>/<nome>.index
#
# Uso:
#   bash voce/aggiungi-voce.sh mia_voce ~/Scaricati/mia_voce.pth ~/Scaricati/added_IVF256_mia_voce.index
#
# Dopo l'aggiunta RIAVVIA il server: i modelli vengono letti solo all'avvio.
#
set -euo pipefail

TTS_RVC_DIR="${TTS_RVC_DIR:-$HOME/TTS-RVC-API}"

if [ $# -ne 3 ]; then
  echo "Uso: $0 <nome_voce> <file.pth> <file.index>" >&2
  exit 1
fi
NAME="$1"; PTH="$2"; INDEX="$3"

case "$NAME" in
  *[!A-Za-z0-9_-]*|"") echo "Nome non valido: usa solo lettere, numeri, _ e -" >&2; exit 1 ;;
esac
[ -f "$PTH" ]   || { echo "File .pth non trovato: $PTH" >&2; exit 1; }
[ -f "$INDEX" ] || { echo "File .index non trovato: $INDEX" >&2; exit 1; }
[ "${PTH##*.}" = "pth" ]     || { echo "Il primo file deve essere .pth" >&2; exit 1; }
[ "${INDEX##*.}" = "index" ] || { echo "Il secondo file deve essere .index" >&2; exit 1; }
[ -d "$TTS_RVC_DIR" ] || { echo "TTS-RVC-API non installato: esegui prima voce/setup-voce.sh" >&2; exit 1; }

DEST="$TTS_RVC_DIR/models/$NAME"
if [ -d "$DEST" ]; then
  echo "==> La voce '$NAME' esiste gia': sostituisco i file."
  # Il server esige ESATTAMENTE un .pth e un .index per cartella.
  rm -f "$DEST"/*.pth "$DEST"/*.index
fi
mkdir -p "$DEST"
cp "$PTH"   "$DEST/$NAME.pth"
cp "$INDEX" "$DEST/$NAME.index"

echo "==> Voce '$NAME' installata in $DEST"
echo "    Riavvia il server (voce/avvia-server.sh) e usa  \"speaker_name\": \"$NAME\""
