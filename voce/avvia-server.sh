#!/usr/bin/env bash
#
# avvia-server.sh
# ---------------
# Avvia l'API TTS-RVC su http://localhost:8000 (documentazione: /docs).
# Se l'installazione manca, lancia prima setup-voce.sh.
#
# Variabili utili:
#   TTS_MODEL   modello Coqui per il testo->voce (default: italiano femminile)
#               es. tts_models/it/mai_male/vits  |  tts_models/en/ljspeech/vits
#   PORT        porta HTTP (default 8000)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TTS_RVC_DIR="${TTS_RVC_DIR:-$HOME/TTS-RVC-API}"
export TTS_MODEL="${TTS_MODEL:-tts_models/it/mai_female/vits}"
PORT="${PORT:-8000}"

if [ ! -x "$TTS_RVC_DIR/.venv/bin/python" ]; then
  echo "==> TTS-RVC-API non ancora installato: avvio l'installazione..."
  bash "$HERE/setup-voce.sh"
fi

# Il server cerca models/, output/ e tmp/ nella directory CORRENTE.
cd "$TTS_RVC_DIR"
# shellcheck disable=SC1091
. .venv/bin/activate

# Accetta automaticamente la licenza dei modelli Coqui (evita la domanda interattiva).
export COQUI_TOS_AGREED=1

echo "==> Modello Coqui : $TTS_MODEL"
echo "==> Voci RVC      : $(ls -1 models 2>/dev/null | grep -v '^hubert$' | tr '\n' ' ')"
echo "==> Server su     : http://localhost:$PORT   (Ctrl+C per fermare)"
echo "    Al primo avvio/richiesta vengono scaricati i modelli: attendi."
echo
exec python -m uvicorn app.main:app --host 0.0.0.0 --port "$PORT"
