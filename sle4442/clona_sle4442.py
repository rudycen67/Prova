#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
clona_sle4442.py — Scrive un dump da 256 byte su una smart card vergine
Infineon SLE4442 (o compatibili SLE5542) con lettore ACS ACR39U, per
clonare/ripristinare una tessera DI CUI SI E' PROPRIETARI.

AVVERTENZA: clona SOLO tessere tue o per cui hai l'autorizzazione.
Duplicare la tessera di un impianto altrui puo' essere illegale.

Come funziona (ACR39 Series Reference Manual v1.05, par. 8.4):
  1. SELECT_CARD_TYPE  FF A4 00 00 01 06      (famiglia 2-wire SLE4442)
  2. PRESENT_CODE      FF 20 00 00 03 <PSC>   (sblocca la scrittura)
     - La lettura non richiede PSC, ma la SCRITTURA si'.
     - Sulle carte vergini il PSC di trasporto e' quasi sempre FF FF FF.
  3. WRITE_MEMORY_CARD FF D0 00 <addr> <len> <dati>   (scrive a blocchi)
  4. Rilettura e confronto byte per byte.

Attenzione al contatore errori PSC: ogni PRESENT_CODE con codice SBAGLIATO
brucia un tentativo. Dopo 3 errori la carta si blocca in scrittura PER
SEMPRE. Questo script presenta il PSC UNA sola volta e si ferma se sbagliato.

I bit di protezione NON vengono scritti (operazione irreversibile): se
l'originale aveva byte protetti in scrittura, quelli NON vengono replicati.
Usa --protect SOLO se sai cosa stai facendo.

Uso:
  python clona_sle4442.py sle4442_dump.bin
  python clona_sle4442.py sle4442_dump.bin --psc FFFFFF
  python clona_sle4442.py sle4442_dump.bin --reader 0 --psc 112233
"""

import argparse
import sys

try:
    from smartcard.System import readers
    from smartcard.util import toHexString, toBytes
    from smartcard.Exceptions import CardConnectionException, NoCardException
except ImportError:
    sys.stderr.write("ERRORE: manca 'pyscard'. Installa con: pip install pyscard\n")
    sys.exit(2)

CARD_TYPE_SLE4442 = 0x06
MEM_SIZE = 256


def sw_ok(sw1, sw2):
    return sw1 == 0x90 and sw2 == 0x00


def transmit(conn, apdu, label):
    data, sw1, sw2 = conn.transmit(list(apdu))
    shown = list(apdu)
    # Non stampare i dati scritti per intero: solo intestazione del comando.
    head = shown[:5] + (["..."] if len(shown) > 5 else [])
    head_txt = " ".join(x if isinstance(x, str) else "%02X" % x for x in head)
    print("  >> %-22s %s" % (label, head_txt))
    print("  << %s + SW=%02X%02X" %
          (toHexString(data) if data else "(nessun dato)", sw1, sw2))
    return data, sw1, sw2


def pick_reader(index):
    rlist = readers()
    if not rlist:
        sys.stderr.write("ERRORE: nessun lettore PC/SC rilevato.\n")
        sys.exit(1)
    print("Lettori disponibili:")
    for i, r in enumerate(rlist):
        print("  [%d] %s" % (i, r))
    if index is not None:
        if index < 0 or index >= len(rlist):
            sys.stderr.write("ERRORE: indice lettore %d non valido.\n" % index)
            sys.exit(1)
        return rlist[index]
    for r in rlist:
        if any(k in str(r).upper() for k in ("ACR39", "ACR38", "ACS")):
            return r
    return rlist[0]


def read_main_memory(conn):
    data, sw1, sw2 = conn.transmit([0xFF, 0xB0, 0x00, 0x00, 0x00])
    if sw_ok(sw1, sw2) and len(data) >= MEM_SIZE:
        return data[:MEM_SIZE]
    full = []
    for addr in range(0, MEM_SIZE, 16):
        d, s1, s2 = conn.transmit([0xFF, 0xB0, 0x00, addr & 0xFF, 16])
        if not sw_ok(s1, s2):
            raise RuntimeError("Rilettura fallita @0x%02X (SW=%02X%02X)"
                               % (addr, s1, s2))
        full.extend(d[:16])
    return full[:MEM_SIZE]


def main():
    ap = argparse.ArgumentParser(
        description="Clona un dump da 256 byte su una SLE4442 vergine.")
    ap.add_argument("dump", help="file .bin sorgente (256 byte)")
    ap.add_argument("--reader", type=int, default=None,
                    help="indice del lettore; default: auto ACR39")
    ap.add_argument("--psc", default="FFFFFF",
                    help="PSC di 3 byte della carta DI DESTINAZIONE "
                         "(default FFFFFF, tipico delle vergini)")
    ap.add_argument("--start", type=lambda x: int(x, 0), default=0x00,
                    help="indirizzo iniziale di scrittura (default 0x00)")
    ap.add_argument("--yes", action="store_true",
                    help="non chiedere conferma prima di scrivere")
    args = ap.parse_args()

    # Carica il dump sorgente.
    try:
        with open(args.dump, "rb") as f:
            src = list(f.read())
    except OSError as e:
        sys.stderr.write("ERRORE: non apro %s: %s\n" % (args.dump, e))
        sys.exit(1)
    if len(src) < MEM_SIZE:
        sys.stderr.write("ERRORE: il dump ha %d byte, ne servono %d.\n"
                         % (len(src), MEM_SIZE))
        sys.exit(1)
    src = src[:MEM_SIZE]

    psc = toBytes(args.psc)
    if len(psc) != 3:
        sys.stderr.write("ERRORE: il PSC deve essere di 3 byte (6 hex).\n")
        sys.exit(1)

    reader = pick_reader(args.reader)
    print("\nUso il lettore: %s\n" % reader)

    conn = reader.createConnection()
    try:
        conn.connect()
    except NoCardException:
        sys.stderr.write("ERRORE: nessuna carta inserita.\n")
        sys.exit(1)
    except CardConnectionException as e:
        sys.stderr.write("ERRORE di connessione: %s\n" % e)
        sys.exit(1)

    print("ATR carta di destinazione: %s\n" % toHexString(conn.getATR()))

    print("Passo 1 - SELECT_CARD_TYPE (SLE4442):")
    _, s1, s2 = transmit(conn, [0xFF, 0xA4, 0x00, 0x00, 0x01, CARD_TYPE_SLE4442],
                         "SELECT_CARD_TYPE")
    if not sw_ok(s1, s2):
        sys.stderr.write("ERRORE: SELECT_CARD_TYPE rifiutato (SW=%02X%02X).\n"
                         % (s1, s2))
        sys.exit(1)

    if not args.yes:
        print("\nATTENZIONE: sto per SCRIVERE 256 byte sulla carta inserita.")
        print("Un PSC errato brucia 1 dei 3 tentativi (3 errori = blocco "
              "scrittura definitivo).")
        resp = input("Procedo con la scrittura? [scrivi SI per continuare] ")
        if resp.strip().upper() not in ("SI", "SÌ", "S", "YES", "Y"):
            print("Annullato. Nessuna scrittura effettuata.")
            conn.disconnect()
            return

    print("\nPasso 2 - PRESENT_CODE (sblocco scrittura, 1 solo tentativo):")
    _, p1, p2 = transmit(conn, [0xFF, 0x20, 0x00, 0x00, 0x03] + list(psc),
                         "PRESENT_CODE")
    if not (p1 == 0x90 and p2 == 0x07):
        sys.stderr.write(
            "\nERRORE: PSC non accettato (SW=%02X%02X).\n"
            "  SW2=07 -> corretto; 00 -> carta bloccata; altro -> errato.\n"
            "  Mi fermo per NON bruciare altri tentativi.\n" % (p1, p2))
        conn.disconnect()
        sys.exit(1)
    print("  PSC corretto: scrittura sbloccata.")

    print("\nPasso 3 - Scrittura memoria a blocchi di 16 byte:")
    chunk = 16
    for addr in range(args.start, MEM_SIZE, chunk):
        block = src[addr:addr + chunk]
        apdu = [0xFF, 0xD0, 0x00, addr & 0xFF, len(block)] + block
        _, w1, w2 = transmit(conn, apdu, "WRITE @0x%02X" % addr)
        if not sw_ok(w1, w2):
            sys.stderr.write("ERRORE: scrittura fallita @0x%02X (SW=%02X%02X)\n"
                             % (addr, w1, w2))
            conn.disconnect()
            sys.exit(1)

    print("\nPasso 4 - Rilettura e verifica:")
    back = read_main_memory(conn)
    diffs = [(i, src[i], back[i]) for i in range(MEM_SIZE) if src[i] != back[i]]
    if not diffs:
        print("  OK: i 256 byte coincidono. Clonazione completata.")
    else:
        print("  ATTENZIONE: %d byte diversi dall'originale:" % len(diffs))
        for i, a, b in diffs[:32]:
            print("    @0x%02X atteso %02X, letto %02X" % (i, a, b))
        if len(diffs) > 32:
            print("    ... e altri %d." % (len(diffs) - 32))
        print("  Cause tipiche: byte protetti in scrittura sulla carta di "
              "destinazione, o area non scrivibile (primi byte identificativi).")

    conn.disconnect()


if __name__ == "__main__":
    main()
