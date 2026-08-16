#!/usr/bin/env bash
#
# clona-tessera.sh
# ----------------
# Aiuto alla clonazione di una tessera LF 125 kHz (chip T5577).
#
# Modi:
#   ./clona-tessera.sh leggi                 legge la SORGENTE e salva tutto in un file
#   ./clona-tessera.sh scrivi <B0> <B1>      scrive i blocchi su una T5577 VERGINE
#   ./clona-tessera.sh restore <file.json>   ripristina un dump su una T5577 VERGINE
#
# Flusso tipico:
#   1) ./clona-tessera.sh leggi   (tessera SORGENTE sull'antenna) -> invia il file
#   2) [ti dico i valori giusti B0/B1 o il file da ripristinare ]
#   3) ./clona-tessera.sh scrivi <B0> <B1>   (tessera VERGINE sull'antenna)
#
set -uo pipefail

# --- client pm3 ---
if command -v pm3 >/dev/null 2>&1; then PM3=pm3
elif [ -x "$HOME/proxmark3/pm3" ]; then PM3="$HOME/proxmark3/pm3"
else echo "❌ Client pm3 non trovato. Esegui prima setup.sh / build-matching-client.sh" >&2; exit 1; fi

# --- porta seriale ---
PORT=""
for p in /dev/ttyACM0 /dev/ttyACM1 /dev/ttyUSB0 /dev/ttyUSB1; do
  [ -e "$p" ] && PORT="$p" && break
done
if [ -z "$PORT" ]; then
  echo "❌ Nessuna porta (/dev/ttyACM*). Collega il device e attaccalo a WSL:" >&2
  echo "   (PowerShell)  usbipd attach --wsl --hardware-id 9ac4:4b8f" >&2
  echo "   (Ubuntu)      sudo modprobe cdc_acm ; ls /dev/ttyACM*" >&2
  exit 1
fi

MODE="${1:-leggi}"

case "$MODE" in
  leggi)
    OUT="$HOME/tessera-sorgente.txt"
    echo "==> Leggo la SORGENTE su $PORT (tienila FERMA e centrata)..."
    "$PM3" -p "$PORT" -c "lf t55xx detect; lf t55xx read -b 0; lf t55xx read -b 0; lf t55xx read -b 1; lf t55xx read -b 1; lf t55xx read -b 2; lf read -s 12000; lf search -1 -u; lf t55xx dump" 2>&1 | tee "$OUT"
    echo
    echo "=============================================================="
    echo " Lettura salvata in: $OUT"
    echo " Inviami QUESTO file (o incollane il contenuto) e ti dico i"
    echo " comandi esatti per scrivere la copia."
    echo "=============================================================="
    ;;

  scrivi)
    B0="${2:-}"; B1="${3:-}"
    if [ -z "$B0" ] || [ -z "$B1" ]; then
      echo "Uso: $0 scrivi <block0-hex> <block1-hex>   (es. $0 scrivi 00148040 1234ABCD)" >&2
      exit 2
    fi
    echo "==> Appoggia la tessera T5577 VERGINE (destinazione), poi premi Invio..."
    read -r _
    echo "==> Scrivo block0=$B0  block1=$B1 ..."
    "$PM3" -p "$PORT" -c "lf t55xx write -b 0 -d $B0; lf t55xx write -b 1 -d $B1; lf t55xx detect; lf search"
    echo "==> Fatto. Prova la copia sul lettore reale."
    ;;

  restore)
    FILE="${2:-}"
    if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
      echo "Uso: $0 restore <file-dump.json>" >&2
      exit 2
    fi
    echo "==> Appoggia la tessera T5577 VERGINE (destinazione), poi premi Invio..."
    read -r _
    "$PM3" -p "$PORT" -c "lf t55xx restore -f $FILE; lf t55xx detect; lf search"
    echo "==> Fatto. Prova la copia sul lettore reale."
    ;;

  *)
    echo "Modi disponibili:"
    echo "  $0 leggi"
    echo "  $0 scrivi <block0-hex> <block1-hex>"
    echo "  $0 restore <file-dump.json>"
    exit 2
    ;;
esac
