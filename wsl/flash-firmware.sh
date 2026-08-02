#!/usr/bin/env bash
#
# flash-firmware.sh
# -----------------
# Flash "sicuro" del firmware Proxmark3 pensato per WSL2.
#
# Problema che risolve: durante il flash il Proxmark3 si riavvia in modalita'
# bootloader e RI-ENUMERA la porta USB (ttyACM0 <-> ttyACM1), staccandosi da
# WSL. Se sul lato Windows e' attivo l'auto-attach (usbipd ... --auto-attach,
# vedi windows/2-attach-proxmark3.ps1) il device viene ri-agganciato da solo e
# il flash prosegue. Questo script verifica i prerequisiti, attende che il
# device sia presente prima e dopo, e conferma l'esito con 'hw version'.
#
# Uso:
#   ./flash-firmware.sh              # flash completo (bootrom + firmware)
#   ./flash-firmware.sh --image      # solo firmware (fullimage), senza bootrom
#   ./flash-firmware.sh --yes        # non chiede conferma
#
set -uo pipefail

PROXMARK_DIR="${PROXMARK_DIR:-$HOME/proxmark3}"
ASSUME_YES=0
FLASH_MODE="all"    # all | image

for arg in "$@"; do
  case "$arg" in
    --yes|-y)      ASSUME_YES=1 ;;
    --image)       FLASH_MODE="image" ;;
    --all)         FLASH_MODE="all" ;;
    -h|--help)
      # stampa solo il blocco commento iniziale (fino alla prima riga non-commento)
      awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"
      exit 0 ;;
    *) echo "Argomento non riconosciuto: $arg" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# Helper: trova la porta seriale del Proxmark3 (vuota se assente)
# ---------------------------------------------------------------------------
find_port() {
  local p
  for p in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
    [ -e "$p" ] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

# Helper: attende la comparsa della porta (timeout in secondi)
wait_for_port() {
  local timeout="${1:-30}" waited=0 port
  while [ "$waited" -lt "$timeout" ]; do
    if port="$(find_port)"; then printf '%s' "$port"; return 0; fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

# ---------------------------------------------------------------------------
# 1) Trova gli strumenti di flash
# ---------------------------------------------------------------------------
FLASH_ALL=""
FLASH_IMG=""
for cand in "pm3-flash-all" "$PROXMARK_DIR/pm3-flash-all"; do
  command -v "$cand" >/dev/null 2>&1 && { FLASH_ALL="$cand"; break; }
  [ -x "$cand" ] && { FLASH_ALL="$cand"; break; }
done
for cand in "pm3-flash-fullimage" "$PROXMARK_DIR/pm3-flash-fullimage"; do
  command -v "$cand" >/dev/null 2>&1 && { FLASH_IMG="$cand"; break; }
  [ -x "$cand" ] && { FLASH_IMG="$cand"; break; }
done

if [ "$FLASH_MODE" = "all" ] && [ -z "$FLASH_ALL" ]; then
  echo "❌ Non trovo 'pm3-flash-all'. Esegui prima ./setup.sh (compila il client)." >&2
  exit 1
fi
if [ "$FLASH_MODE" = "image" ] && [ -z "$FLASH_IMG" ]; then
  echo "❌ Non trovo 'pm3-flash-fullimage'. Esegui prima ./setup.sh." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 2) Il device e' presente?
# ---------------------------------------------------------------------------
echo "==> Cerco il Proxmark3..."
if ! PORT="$(find_port)"; then
  cat >&2 <<'EOF'
❌ Nessuna porta seriale trovata: il Proxmark3 non risulta agganciato a WSL.
   Da PowerShell (Amministratore):
       usbipd attach --wsl --hardware-id 9ac4:4b8f
   e assicurati che l'AUTO-ATTACH sia attivo prima di flashare.
EOF
  exit 1
fi
echo "    Trovato su: $PORT"

# ---------------------------------------------------------------------------
# 3) Avviso e conferma
# ---------------------------------------------------------------------------
cat <<EOF

============================ ATTENZIONE ============================
Sto per FLASHARE il firmware del Proxmark3 (modalita': $FLASH_MODE).

Durante il processo il device si riavviera' in bootloader e cambiera'
porta USB: se l'AUTO-ATTACH lato Windows NON e' attivo, il flash puo'
interrompersi. Verifica che sia in esecuzione:

  - windows/2-attach-proxmark3.ps1 (auto-attach), oppure
  - l'attivita' pianificata 'Proxmark3-WSL-AutoAttach'.

NON scollegare il device durante il flash.
===================================================================

EOF

if [ "$ASSUME_YES" -ne 1 ]; then
  printf "Procedo con il flash? [s/N] "
  read -r reply
  case "$reply" in
    s|S|y|Y) ;;
    *) echo "Annullato."; exit 0 ;;
  esac
fi

# ---------------------------------------------------------------------------
# 4) Flash
# ---------------------------------------------------------------------------
echo
echo "==> Avvio il flash. Tieni d'occhio l'output..."
set +e
if [ "$FLASH_MODE" = "all" ]; then
  "$FLASH_ALL"
else
  "$FLASH_IMG"
fi
rc=$?
set -e 2>/dev/null || true

echo
if [ "$rc" -ne 0 ]; then
  echo "⚠️  Il flasher e' uscito con codice $rc." >&2
  echo "    Se il device e' rimasto in bootloader, ricontrolla l'auto-attach e" >&2
  echo "    rilancia:  ./flash-firmware.sh --image --yes" >&2
fi

# ---------------------------------------------------------------------------
# 5) Attendi il ritorno del device e conferma
# ---------------------------------------------------------------------------
echo "==> Attendo che il Proxmark3 torni disponibile..."
if NEWPORT="$(wait_for_port 45)"; then
  echo "    Device di nuovo presente su: $NEWPORT"
  echo "==> Verifico la versione dopo il flash:"
  if [ -x "./check-firmware.sh" ]; then
    ./check-firmware.sh || true
  else
    "${PROXMARK_DIR}/pm3" -p "$NEWPORT" -c 'hw version' || true
  fi
else
  echo "⚠️  Il device non e' ricomparso entro il timeout." >&2
  echo "    Ricollegalo / rifai l'attach usbipd e poi lancia ./check-firmware.sh" >&2
  exit 1
fi

echo
echo "==> Flash terminato."
