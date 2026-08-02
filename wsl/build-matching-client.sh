#!/usr/bin/env bash
#
# build-matching-client.sh
# ------------------------
# Compila un client pm3 IDENTICO al firmware attualmente installato sul
# Proxmark3, per evitare qualsiasi mismatch client/firmware.
#
# Strategia (il firmware NON viene toccato):
#   1. build iniziale del client (serve solo per parlare col device);
#   2. legge 'hw version' e ricava il COMMIT git del firmware installato;
#   3. checkout di quel commit esatto (stesso fork del firmware);
#   4. ricompila il client -> ora client e firmware sono identici;
#   5. verifica finale (nessun 'mismatch').
#
# Uso:
#   ./build-matching-client.sh
#   PLATFORM=PM3RDV4 ./build-matching-client.sh   # forza la piattaforma RDV4
#
set -uo pipefail

PROXMARK_DIR="${PROXMARK_DIR:-$HOME/proxmark3}"
PLATFORM="${PLATFORM:-}"          # se vuoto, viene rilevata dal device
RRG_URL="https://github.com/RfidResearchGroup/proxmark3.git"
OFFICIAL_URL="https://github.com/Proxmark/proxmark3.git"

# ---------------------------------------------------------------------------
# Helper porta seriale
# ---------------------------------------------------------------------------
find_port() {
  local p
  for p in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
    [ -e "$p" ] && { printf '%s' "$p"; return 0; }
  done
  return 1
}
wait_for_port() {
  local t="${1:-20}" i=0 p
  while [ "$i" -lt "$t" ]; do
    if p="$(find_port)"; then printf '%s' "$p"; return 0; fi
    sleep 1; i=$((i+1))
  done
  return 1
}

read_hw_version() {   # $1 = pm3 binary, $2 = port
  timeout 45 "$1" -p "$2" -c 'hw version' 2>&1 || true
}

# ---------------------------------------------------------------------------
# 0) Dipendenze di build (idempotente)
# ---------------------------------------------------------------------------
echo "==> Installo/verifico le dipendenze di build..."
sudo apt update -qq
sudo apt install -y --no-install-recommends \
  git ca-certificates build-essential pkg-config \
  libreadline-dev gcc-arm-none-eabi libnewlib-dev \
  qtbase5-dev libbz2-dev libbluetooth-dev \
  libpython3-dev libssl-dev libgd-dev usbutils
sudo usermod -aG dialout "$USER" 2>/dev/null || true
sudo modprobe cdc_acm 2>/dev/null || true

# ---------------------------------------------------------------------------
# 1) Attendo il device
# ---------------------------------------------------------------------------
echo "==> Cerco il Proxmark3..."
if ! PORT="$(wait_for_port 20)"; then
  echo "❌ Proxmark3 non trovato (/dev/ttyACM*). Collegalo e assicurati che sia" >&2
  echo "   agganciato a WSL (usbipd attach --wsl --hardware-id 9ac4:4b8f)." >&2
  exit 1
fi
echo "    Trovato su: $PORT"

# ---------------------------------------------------------------------------
# 2) Clone + build iniziale (per leggere il firmware)
# ---------------------------------------------------------------------------
if [ ! -d "$PROXMARK_DIR/.git" ]; then
  echo "==> Clono il sorgente (RRG/Iceman)..."
  git clone "$RRG_URL" "$PROXMARK_DIR"
fi
cd "$PROXMARK_DIR"

echo "==> Build iniziale del client (per interrogare il device)..."
make clean >/dev/null 2>&1 || true
make -j"$(nproc)" client >/dev/null

# ---------------------------------------------------------------------------
# 3) Leggo la versione del firmware e ricavo il commit
# ---------------------------------------------------------------------------
echo "==> Leggo il firmware dal device..."
OUT="$(read_hw_version "$PROXMARK_DIR/pm3" "$PORT")"
if ! printf '%s' "$OUT" | grep -qiE 'os|bootrom|proxmark'; then
  echo "❌ Non riesco a leggere 'hw version'. Output:" >&2
  printf '%s\n' "$OUT" >&2
  exit 1
fi

os_line=$(printf '%s\n' "$OUT" | grep -iw 'os' | grep -iE 'v[0-9]' | head -n1)
echo "    Firmware: ${os_line:-non rilevato}"

# Fork
if printf '%s' "$OUT" | grep -qiE 'proxmark\.org' && ! printf '%s' "$os_line" | grep -qiE 'iceman|RRG'; then
  echo "⚠️  Il firmware sembra UFFICIALE (proxmark.org), non Iceman/RRG."
  echo "    Passo al repository ufficiale per far combaciare il client."
  if [ ! -d "${PROXMARK_DIR}-official/.git" ]; then
    git clone "$OFFICIAL_URL" "${PROXMARK_DIR}-official"
  fi
  PROXMARK_DIR="${PROXMARK_DIR}-official"
  cd "$PROXMARK_DIR"
  make clean >/dev/null 2>&1 || true
  make -j"$(nproc)" client >/dev/null || true
fi

# Piattaforma (RDV4 vs generico) se non forzata
if [ -z "$PLATFORM" ]; then
  if printf '%s' "$OUT" | grep -qiE 'RDV4'; then PLATFORM="PM3RDV4"; else PLATFORM="PM3GENERIC"; fi
fi
echo "    Piattaforma: $PLATFORM"

# Commit git dal 'git describe' incorporato nel firmware (suffisso -g<hash>)
commit=$(printf '%s' "$os_line" | grep -oiE 'g[0-9a-f]{7,}' | head -n1 | sed 's/^[gG]//')
tag=$(printf '%s' "$os_line" | grep -oiE 'v[0-9][0-9.]*' | head -n1)

# ---------------------------------------------------------------------------
# 4) Checkout della versione ESATTA e ricompilazione
# ---------------------------------------------------------------------------
git fetch --all --tags --quiet || true

target=""
if [ -n "$commit" ] && git cat-file -e "${commit}^{commit}" 2>/dev/null; then
  target="$commit"
  echo "==> Mi allineo al commit del firmware: $commit"
elif [ -n "$tag" ] && git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
  target="refs/tags/${tag}"
  echo "==> Mi allineo al tag del firmware: $tag"
else
  echo "⚠️  Non riesco a individuare il commit/tag esatto del firmware."
  echo "    Tengo la versione piu' recente del client. Se compare un 'mismatch',"
  echo "    aggiorna il firmware alla versione del client oppure indicami la versione."
fi

if [ -n "$target" ]; then
  git checkout --quiet "$target"
  echo "==> Ricompilo il client sulla versione del firmware (PLATFORM=$PLATFORM)..."
  make clean >/dev/null 2>&1 || true
  make -j"$(nproc)" PLATFORM="$PLATFORM" client
fi

echo "==> Installo il client nel sistema..."
sudo make install PLATFORM="$PLATFORM" 2>/dev/null || sudo make install || true

# ---------------------------------------------------------------------------
# 5) Verifica finale
# ---------------------------------------------------------------------------
echo "==> Verifica finale (client vs firmware)..."
PORT="$(wait_for_port 20 || echo "$PORT")"
OUT2="$(read_hw_version "$PROXMARK_DIR/pm3" "$PORT")"
printf '%s\n' "$OUT2" | grep -iE 'client|os|bootrom|mismatch' || true

echo
if printf '%s' "$OUT2" | grep -qiE 'mismatch'; then
  echo "⚠️  Persiste un mismatch. Probabilmente il commit del firmware non e' piu'"
  echo "    reperibile nel repo pubblico. Opzioni: aggiornare il firmware alla"
  echo "    versione del client (wsl/flash-firmware.sh) o accettare il warning."
else
  echo "✅ Client allineato al firmware installato. Nessun mismatch rilevato."
fi
