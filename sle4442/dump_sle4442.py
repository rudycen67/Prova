#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
dump_sle4442.py — Dump completo di una smart card a memoria sincrona
Infineon SLE4442 (o compatibili SLE4432/SLE5532/SLE5542) con lettore
ACS ACR39U (e famiglia ACR38/ACR39) su Windows, Linux o macOS.

PERCHE' I TENTATIVI PRECEDENTI FALLIVANO (buffer di risposta vuoto []):
  1. I comandi per le memory card ACS NON vanno inviati sul canale di
     escape/IOCTL (connection.control / SCardControl). Vanno inviati come
     normali pseudo-APDU sul canale dati PC/SC (connection.transmit /
     SCardTransmit), dopo un normale SCardConnect.
  2. Prima di qualsiasi lettura bisogna inviare SELECT_CARD_TYPE
     (FF A4 00 00 01 06), dove 0x06 e' il codice ACS per la famiglia
     2-wire SLE4432/SLE4442. Senza questo comando il firmware non sa
     come pilotare i segnali Clock/Data a 2 fili e ogni lettura torna
     vuota. Il firmware del lettore gestisce lui la sequenza fisica
     clock/data: non serve nessun bit-banging ne' escape proprietario.

Set di comandi (ACS ACR39 Series Reference Manual v1.05, par. 8.4):
  SELECT_CARD_TYPE .............. FF A4 00 00 01 06       -> 90 00
  READ_MEMORY_CARD .............. FF B0 00 <addr> <len>   -> <dati...> 90 00
  READ_PRESENTATION_ERR_COUNTER . FF B1 00 00 04          -> <EC> xx xx xx 90 00
  READ_PROTECTION_BITS .......... FF B2 00 00 04          -> <P1..P4> 90 00
  WRITE_MEMORY_CARD ............. FF D0 00 <addr> <len> <dati...>  (non usato qui)
  PRESENT_CODE (PSC) ............ FF 20 00 00 03 <p1 p2 p3> -> 90 <EC>
  CHANGE_CODE ................... FF D2 00 01 03 <p1 p2 p3> (non usato qui)

NOTE SULLA SICUREZZA DELLA CARTA:
  - La memoria principale (256 byte) e' leggibile SENZA presentare il PSC.
  - Il PSC (3 byte) NON e' mai leggibile in chiaro: nell'area di sicurezza
    e' mascherato. E' richiesto solo per ABILITARE la scrittura.
  - Questo script di default fa SOLO letture. Il PSC (opzione --psc) viene
    usato unicamente per verificarlo e sbloccare eventuali scritture: qui
    non viene eseguita alcuna scrittura.

Dipendenza:  pip install pyscard
  (su Windows pyscard usa il servizio WinSCard gia' presente; il lettore
   ACR39U e' CCID, quindi nessun driver aggiuntivo oltre a quello ACS.)

Uso:
  python dump_sle4442.py                    # dump su stdout + file .bin
  python dump_sle4442.py --out tessera.bin  # scegli il nome del file
  python dump_sle4442.py --reader 0         # scegli il lettore per indice
  python dump_sle4442.py --psc FFFFFF       # verifica il PSC (facoltativo)
"""

import argparse
import sys

try:
    from smartcard.System import readers
    from smartcard.util import toHexString, toBytes
    from smartcard.Exceptions import CardConnectionException, NoCardException
except ImportError:
    sys.stderr.write(
        "ERRORE: manca la libreria 'pyscard'.\n"
        "Installala con:  pip install pyscard\n"
    )
    sys.exit(2)

# Codice carta ACS per la famiglia 2-wire SLE4432/SLE4442/SLE5532/SLE5542.
CARD_TYPE_SLE4442 = 0x06

MEM_SIZE = 256  # byte di memoria principale della SLE4442


def sw_ok(sw1, sw2):
    """Status word 90 00 = nessun errore."""
    return sw1 == 0x90 and sw2 == 0x00


def transmit(conn, apdu, label):
    """Invia una pseudo-APDU sul canale dati e restituisce (dati, sw1, sw2)."""
    data, sw1, sw2 = conn.transmit(list(apdu))
    print("  >> %-28s %s" % (label, toHexString(list(apdu))))
    tail = " + SW=%02X%02X" % (sw1, sw2)
    print("  << %s%s" % (toHexString(data) if data else "(nessun dato)", tail))
    return data, sw1, sw2


def pick_reader(index):
    rlist = readers()
    if not rlist:
        sys.stderr.write(
            "ERRORE: nessun lettore PC/SC rilevato.\n"
            "Verifica che il servizio Smart Card sia attivo e che l'ACR39U "
            "sia collegato.\n"
        )
        sys.exit(1)
    print("Lettori disponibili:")
    for i, r in enumerate(rlist):
        print("  [%d] %s" % (i, r))
    if index is not None:
        if index < 0 or index >= len(rlist):
            sys.stderr.write("ERRORE: indice lettore %d non valido.\n" % index)
            sys.exit(1)
        return rlist[index]
    # Preferisci un ACR39/ACR38 se presente, altrimenti il primo.
    for r in rlist:
        name = str(r).upper()
        if "ACR39" in name or "ACR38" in name or "ACS" in name:
            return r
    return rlist[0]


def read_main_memory(conn):
    """
    Legge i 256 byte di memoria principale.
    Prima prova una lettura unica (len=0x00 => 256 su molti firmware ACS);
    se non torna l'intero blocco, ripiega su letture a blocchi di 16 byte.
    """
    # Tentativo 1: lettura unica dei 256 byte.
    data, sw1, sw2 = transmit(
        conn, [0xFF, 0xB0, 0x00, 0x00, 0x00], "READ_MEMORY (256B)"
    )
    if sw_ok(sw1, sw2) and len(data) >= MEM_SIZE:
        return data[:MEM_SIZE]

    # Tentativo 2: letture a blocchi di 16 byte, indirizzi 0x00..0xFF.
    print("  (lettura unica incompleta: passo a letture a blocchi di 16 byte)")
    full = []
    chunk = 16
    for addr in range(0, MEM_SIZE, chunk):
        d, s1, s2 = transmit(
            conn,
            [0xFF, 0xB0, 0x00, addr & 0xFF, chunk],
            "READ_MEMORY @0x%02X" % addr,
        )
        if not sw_ok(s1, s2):
            raise RuntimeError(
                "Lettura fallita all'indirizzo 0x%02X (SW=%02X%02X)"
                % (addr, s1, s2)
            )
        full.extend(d[:chunk])
    return full[:MEM_SIZE]


def hexdump(data):
    """Dump classico 16 byte per riga: offset, esadecimale, ASCII."""
    out = []
    for off in range(0, len(data), 16):
        row = data[off:off + 16]
        hexpart = " ".join("%02X" % b for b in row)
        hexpart = "%-47s" % hexpart
        asc = "".join(chr(b) if 32 <= b < 127 else "." for b in row)
        out.append("%04X  %s  |%s|" % (off, hexpart, asc))
    return "\n".join(out)


def describe_error_counter(ec):
    if ec == 0x07:
        return "0x07 = contatore pieno, 3 tentativi PSC disponibili"
    if ec == 0x00:
        return "0x00 = carta BLOCCATA in scrittura (tentativi PSC esauriti)"
    # I bit a '1' nel contatore sono i tentativi ancora disponibili.
    rimasti = bin(ec).count("1")
    return ("0x%02X = PSC gia' fallito almeno una volta, %d tentativi rimasti"
            % (ec, rimasti))


def main():
    ap = argparse.ArgumentParser(
        description="Dump di una smart card SLE4442 con lettore ACS ACR39U."
    )
    ap.add_argument("--reader", type=int, default=None,
                    help="indice del lettore (vedi elenco); default: auto ACR39")
    ap.add_argument("--out", default="sle4442_dump.bin",
                    help="file binario di output (default: sle4442_dump.bin)")
    ap.add_argument("--psc", default=None,
                    help="PSC di 3 byte in esadecimale, es. FFFFFF, SOLO per "
                         "verifica (facoltativo; non esegue scritture)")
    args = ap.parse_args()

    reader = pick_reader(args.reader)
    print("\nUso il lettore: %s\n" % reader)

    conn = reader.createConnection()
    try:
        conn.connect()  # connessione PC/SC normale (NON SCARD_SHARE_DIRECT)
    except NoCardException:
        sys.stderr.write("ERRORE: nessuna carta inserita nel lettore.\n")
        sys.exit(1)
    except CardConnectionException as e:
        sys.stderr.write("ERRORE di connessione: %s\n" % e)
        sys.exit(1)

    atr = conn.getATR()
    print("ATR carta: %s\n" % toHexString(atr))

    print("Passo 1 - SELECT_CARD_TYPE (famiglia 2-wire SLE4442, 0x06):")
    _, sw1, sw2 = transmit(
        conn, [0xFF, 0xA4, 0x00, 0x00, 0x01, CARD_TYPE_SLE4442],
        "SELECT_CARD_TYPE"
    )
    if not sw_ok(sw1, sw2):
        sys.stderr.write(
            "\nERRORE: SELECT_CARD_TYPE rifiutato (SW=%02X%02X).\n"
            "Il lettore non ha accettato la selezione del tipo carta.\n"
            % (sw1, sw2)
        )
        sys.exit(1)

    print("\nPasso 2 - Lettura memoria principale (256 byte):")
    mem = read_main_memory(conn)

    print("\nPasso 3 - Lettura bit di protezione (primi 32 byte):")
    prot, ps1, ps2 = transmit(conn, [0xFF, 0xB2, 0x00, 0x00, 0x04],
                              "READ_PROTECTION_BITS")

    print("\nPasso 4 - Lettura contatore errori di presentazione PSC:")
    sec, es1, es2 = transmit(conn, [0xFF, 0xB1, 0x00, 0x00, 0x04],
                             "READ_ERROR_COUNTER")

    if args.psc is not None:
        psc = toBytes(args.psc)
        if len(psc) != 3:
            sys.stderr.write("ERRORE: il PSC deve essere di 3 byte (6 hex).\n")
            sys.exit(1)
        print("\nPasso 5 (facoltativo) - Verifica PSC:")
        print("  ATTENZIONE: un PSC errato CONSUMA un tentativo (3 errori = "
              "blocco scrittura definitivo).")
        _, vs1, vs2 = transmit(conn, [0xFF, 0x20, 0x00, 0x00, 0x03] + psc,
                               "PRESENT_CODE")
        if vs1 == 0x90 and vs2 == 0x07:
            print("  PSC CORRETTO (scritture sbloccate per questa sessione).")
        elif vs1 == 0x90 and vs2 == 0x00:
            print("  PSC errato: carta BLOCCATA in scrittura (tentativi esauriti).")
        else:
            # Il contatore (SW2) e' un valore come 07/03/01/00: i bit a '1'
            # sono i tentativi ancora disponibili.
            rimasti = bin(vs2).count("1")
            print("  PSC ERRATO (SW=%02X%02X). Tentativi di scrittura rimasti: %d."
                  % (vs1, vs2, rimasti))
            print("  NON provare altri codici a caso: rischi di bloccare la carta.")
        # Rileggo il contatore DOPO il tentativo, cosi' il riepilogo mostra lo
        # stato reale e aggiornato (la lettura non consuma tentativi).
        sec, es1, es2 = conn.transmit([0xFF, 0xB1, 0x00, 0x00, 0x04])

    # ---- Report finale -----------------------------------------------------
    print("\n" + "=" * 60)
    print("DUMP MEMORIA PRINCIPALE SLE4442 (%d byte)" % len(mem))
    print("=" * 60)
    print(hexdump(mem))

    print("\nAREA DI SICUREZZA / PROTEZIONE")
    print("-" * 60)
    if sw_ok(ps1, ps2):
        print("Bit di protezione (primi 32 byte): %s" % toHexString(prot))
        print("  '1' = byte scrivibile, '0' = byte protetto in scrittura")
    else:
        print("Bit di protezione non letti (SW=%02X%02X)" % (ps1, ps2))
    if sw_ok(es1, es2) and sec:
        print("Contatore errori PSC: %s" % describe_error_counter(sec[0]))
        print("  (I 3 byte del PSC non sono mai leggibili in chiaro.)")
    else:
        print("Contatore errori non letto (SW=%02X%02X)" % (es1, es2))

    with open(args.out, "wb") as f:
        f.write(bytes(mem))
    print("\nMemoria principale salvata in: %s" % args.out)

    conn.disconnect()


if __name__ == "__main__":
    main()
