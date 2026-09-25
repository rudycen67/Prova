#!/usr/bin/env bash
#
# setup-voce.sh
# -------------
# Installa TTS-RVC-API (Coqui TTS + RVC) su Ubuntu/WSL2.
# Da eseguire UNA SOLA VOLTA (o quando vuoi aggiornare).
#
#   Coqui TTS  -> trasforma il testo in voce (voce "base")
#   RVC        -> converte la voce base nel timbro del tuo modello .pth/.index
#
# Uso:
#   bash voce/setup-voce.sh
#   TTS_RVC_DIR=/percorso/altro bash voce/setup-voce.sh
#
set -euo pipefail

TTS_RVC_DIR="${TTS_RVC_DIR:-$HOME/TTS-RVC-API}"
TTS_RVC_REPO="${TTS_RVC_REPO:-https://github.com/skshadan/TTS-RVC-API.git}"
PY=python3.10   # fairseq 0.12.2 e Coqui TTS 0.22 NON funzionano con Python >= 3.12

echo "==> Directory installazione: $TTS_RVC_DIR"
echo

echo "==> Installo le dipendenze di sistema (ffmpeg, git, build tools)..."
sudo apt update
sudo apt install -y --no-install-recommends \
  git git-lfs ca-certificates build-essential ffmpeg libsndfile1 curl unzip

if ! command -v "$PY" >/dev/null 2>&1; then
  echo "==> Python 3.10 non presente: lo installo (PPA deadsnakes)..."
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt update
fi
sudo apt install -y --no-install-recommends python3.10 python3.10-venv python3.10-dev

echo "==> Scarico/aggiorno TTS-RVC-API..."
if [ -d "$TTS_RVC_DIR/.git" ]; then
  git -C "$TTS_RVC_DIR" pull --ff-only || echo "   (pull saltato: modifiche locali presenti)"
else
  git clone --depth 1 "$TTS_RVC_REPO" "$TTS_RVC_DIR"
fi
cd "$TTS_RVC_DIR"
git lfs pull 2>/dev/null || true   # modelli di esempio, se salvati con LFS

echo "==> Rendo configurabile il modello Coqui (variabile TTS_MODEL)..."
# Upstream usa un modello solo inglese fisso. Con questa patch avvia-server.sh
# puo' scegliere il modello (di default: italiano).
if ! grep -q 'TTS_MODEL' app/routers/tts.py; then
  sed -i 's|TTS(model_name="tts_models/en/ljspeech/vits"|TTS(model_name=os.environ.get("TTS_MODEL", "tts_models/en/ljspeech/vits")|' \
    app/routers/tts.py
fi
grep -q 'TTS_MODEL' app/routers/tts.py \
  || echo "   ATTENZIONE: patch non applicata (il codice upstream e' cambiato); resta il modello inglese."

echo "==> Creo l'ambiente virtuale Python 3.10 (.venv)..."
[ -d .venv ] || "$PY" -m venv .venv
# shellcheck disable=SC1091
. .venv/bin/activate
pip install --upgrade pip "setuptools<70" wheel

echo "==> Installo le dipendenze (puo' richiedere molti minuti: PyTorch e' grande)..."
pip install -r requirements.txt
# Come da README upstream, TTS va installato DOPO: pip aggiorna da solo
# numpy/scipy alle versioni richieste da Coqui TTS 0.22.
pip install "TTS==0.22.0"

echo "==> Scarico il tokenizzatore NLTK 'punkt'..."
python -c "import nltk; nltk.download('punkt', quiet=True)"

mkdir -p models
echo
echo "============================================================"
echo " Installazione completata."
echo " Modelli RVC presenti in $TTS_RVC_DIR/models:"
ls -1 models 2>/dev/null | sed 's/^/   - /' || true
echo
echo " Aggiungi la TUA voce:  bash voce/aggiungi-voce.sh <nome> <file.pth> <file.index>"
echo " Avvia il server:       bash voce/avvia-server.sh"
echo "============================================================"
