#!/usr/bin/env bash
#
# check-firmware.sh
# -----------------
# Interroga il Proxmark3 collegato, legge il firmware attualmente installato
# e indica quale client/piattaforma usare (e se serve un aggiornamento/flash).
#
# Non richiede argomenti: trova da solo il client e la porta seriale.
#
set -uo pipefail

# ---------------------------------------------------------------------------
# 1) Trova il client pm3
# ---------------------------------------------------------------------------
if command -v pm3 >/dev/null 2>&1; then
  PM3="pm3"
elif [ -x "$HOME/proxmark3/pm3" ]; then
  PM3="$HOME/proxmark3/pm3"
else
  echo "❌ Client pm3 non trovato. Esegui prima ./setup.sh" >&2
  exit 1
fi
echo "==> Client pm3: $PM3"

# ---------------------------------------------------------------------------
# 2) Trova la porta seriale del Proxmark3
# ---------------------------------------------------------------------------
PORT=""
for p in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
  [ -e "$p" ] && PORT="$p" && break
done

if [ -z "$PORT" ]; then
  cat >&2 <<'EOF'
❌ Nessuna porta seriale (/dev/ttyACM*) trovata.

   Controlla che:
   1) il Proxmark3 sia collegato alla USB;
   2) da PowerShell (Amministratore) sia stato eseguito l'attach a WSL:
          usbipd attach --wsl --hardware-id 9ac4:4b8f
      (oppure che l'auto-attach sia attivo).

   Verifica poi in WSL con:
          lsusb
          ls -l /dev/ttyACM*
EOF
  exit 1
fi
echo "==> Porta seriale: $PORT"
echo

# ---------------------------------------------------------------------------
# 3) Interroga il dispositivo (comando singolo, non interattivo)
# ---------------------------------------------------------------------------
echo "==> Leggo la versione dal dispositivo (hw version)..."
OUT="$(timeout 45 "$PM3" -p "$PORT" -c 'hw version' 2>&1 || true)"

if [ -z "$OUT" ] || ! printf '%s' "$OUT" | grep -qiE 'os|bootrom|proxmark'; then
  echo "❌ Non riesco a leggere la versione dal dispositivo." >&2
  echo "   Output ricevuto:" >&2
  printf '%s\n' "$OUT" >&2
  echo >&2
  echo "   Suggerimenti: il device potrebbe essere in modalita' bootloader," >&2
  echo "   oppure la porta e' occupata da un'altra istanza di pm3." >&2
  exit 1
fi

echo "----------------------------------------------------------------"
printf '%s\n' "$OUT"
echo "----------------------------------------------------------------"

# ---------------------------------------------------------------------------
# 4) Estrai le informazioni chiave (il formato dei campi varia tra versioni,
#    quindi la ricerca e' volutamente tollerante).
# ---------------------------------------------------------------------------
# Formato vecchio: riga "client: <versione>"; formato nuovo: la versione sta
# sulla prima riga non vuota SOTTO l'header "[ Client ]".
client_line=$(printf '%s\n' "$OUT" | grep -iw 'client' | grep -iE 'v[0-9]' | head -n1)
if [ -z "$client_line" ]; then
  client_line=$(printf '%s\n' "$OUT" | awk 'f && NF { sub(/^[[:space:]]+/,""); print; exit } /\[[[:space:]]*Client[[:space:]]*\]/ { f=1 }')
fi
os_line=$(printf '%s\n'     "$OUT" | grep -iw 'os'     | grep -iE 'v[0-9]' | head -n1)
boot_line=$(printf '%s\n'   "$OUT" | grep -iw 'bootrom'| grep -iE 'v[0-9]' | head -n1)

# Fork del firmware installato sul dispositivo
fw_fork="Sconosciuto"
if printf '%s' "$os_line" | grep -qiE 'iceman|RRG|rfidresearch'; then
  fw_fork="Iceman / RfidResearchGroup (RRG)"
elif printf '%s' "$OUT" | grep -qiE 'proxmark\.org'; then
  fw_fork="Ufficiale (proxmark.org)"
fi

# Hardware: RDV4 oppure generico?
platform="PM3GENERIC"
hw_type="Generico (PM3 Easy / EVO / clone...)"
if printf '%s' "$OUT" | grep -qiE 'RDV4'; then
  platform="PM3RDV4"
  hw_type="Proxmark3 RDV4"
fi

# Versioni (per confronto client vs firmware)
client_ver=$(printf '%s' "$client_line" | grep -oiE 'v[0-9][0-9.]*' | head -n1)
os_ver=$(printf '%s'     "$os_line"     | grep -oiE 'v[0-9][0-9.]*' | head -n1)

# ---------------------------------------------------------------------------
# 5) Riepilogo
# ---------------------------------------------------------------------------
echo
echo "======================= RIEPILOGO ============================="
echo "Firmware (OS) sul dispositivo : ${os_line:-non rilevato}"
echo "Bootrom                       : ${boot_line:-non rilevato}"
echo "Client attualmente installato : ${client_line:-non rilevato}"
echo "Fork del firmware             : $fw_fork"
echo "Hardware rilevato             : $hw_type"
echo "PLATFORM consigliata          : $platform"
echo "==============================================================="
echo

# Allineamento client <-> firmware
if printf '%s' "$OUT" | grep -qiE 'mismatch'; then
  echo "⚠️  Il client segnala un MISMATCH tra versione del client e del firmware."
elif [ -n "$client_ver" ] && [ -n "$os_ver" ]; then
  if [ "$client_ver" = "$os_ver" ]; then
    echo "✅ Client e firmware sono ALLINEATI ($client_ver): sei operativo."
  else
    echo "⚠️  Versioni DIVERSE -> client: $client_ver | firmware: $os_ver"
  fi
fi
echo

# ---------------------------------------------------------------------------
# 6) Cosa fare
# ---------------------------------------------------------------------------
echo "----------------------- COSA FARE -----------------------------"
case "$fw_fork" in
  Iceman*)
    echo "• Il dispositivo ha gia' il firmware Iceman/RRG: usa il client Iceman"
    echo "  (quello compilato da setup.sh). E' la configurazione consigliata."
    echo "• Se le versioni non coincidono, riallinea aggiornando il firmware"
    echo "  alla stessa versione del client:"
    echo "      cd ~/proxmark3 && make clean && make -j\$(nproc) PLATFORM=$platform"
    echo "      ./pm3-flash-all"
    ;;
  Ufficiale*)
    echo "• Il dispositivo ha il firmware UFFICIALE (proxmark.org)."
    echo "  Opzione A (consigliata): passa al fork Iceman riflashando il device:"
    echo "      cd ~/proxmark3 && make clean && make -j\$(nproc) PLATFORM=$platform && ./pm3-flash-all"
    echo "  Opzione B: se vuoi restare sull'ufficiale, compila QUEL client:"
    echo "      git clone https://github.com/Proxmark/proxmark3.git"
    ;;
  *)
    echo "• Fork non identificato con certezza: leggi il blocco 'os:' qui sopra."
    echo "  In generale il client Iceman/RRG e' quello consigliato e piu' compatibile."
    ;;
esac

if [ "$platform" = "PM3RDV4" ]; then
  echo
  echo "ℹ️  Rilevato un RDV4: assicurati di aver compilato con PLATFORM=PM3RDV4."
  echo "    Se non l'hai fatto, ricompila:  PLATFORM=PM3RDV4 ./setup.sh"
fi
echo "==============================================================="
