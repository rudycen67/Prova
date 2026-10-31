#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sle4442_gui.py - Programma Windows con interfaccia grafica per LEGGERE e
SCRIVERE smart card Infineon SLE4442 (e compatibili SLE5542) con lettore
ACS ACR39U (famiglia ACR38/ACR39).

Funzioni:
  - Legge i 256 byte di memoria + bit di protezione + contatore errori PSC
  - Mostra un dump esadecimale/ASCII
  - Salva/carica il dump su file .bin
  - Scrive (clona) un dump su una carta, presentando il PSC
  - Azzera una carta (scrive tutti FF)

Dipendenze: Python 3 + pyscard (pip install pyscard).
Tkinter e' gia' incluso in Python su Windows.

ATTENZIONE PSC: un PSC errato in scrittura CONSUMA un tentativo; dopo 3
errori la carta si blocca in scrittura PER SEMPRE. Il programma presenta il
PSC una sola volta e si ferma se sbagliato.

Scopo: duplicare/gestire ESCLUSIVAMENTE carte proprie o autorizzate.
"""

import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

try:
    from smartcard.System import readers
    from smartcard.util import toBytes
    from smartcard.Exceptions import CardConnectionException, NoCardException
    PYSCARD_OK = True
    PYSCARD_ERR = ""
except Exception as e:                      # noqa
    PYSCARD_OK = False
    PYSCARD_ERR = str(e)

CARD_TYPE_SLE4442 = 0x06
MEM_SIZE = 256


class SLE4442App:
    def __init__(self, root):
        self.root = root
        self.mem = [0xFF] * MEM_SIZE
        self.busy = False
        root.title("SLE4442 Tool - lettura e scrittura (ACR39U)")
        root.geometry("760x620")
        self._build_ui()
        self.refresh_readers()

    # ---------- Costruzione interfaccia ----------
    def _build_ui(self):
        top = ttk.Frame(self.root, padding=8)
        top.pack(fill="x")

        ttk.Label(top, text="Lettore:").pack(side="left")
        self.reader_cb = ttk.Combobox(top, width=42, state="readonly")
        self.reader_cb.pack(side="left", padx=4)
        ttk.Button(top, text="Aggiorna", command=self.refresh_readers).pack(
            side="left", padx=2)

        ttk.Label(top, text="PSC:").pack(side="left", padx=(16, 2))
        self.psc_var = tk.StringVar(value="FFFFFF")
        ttk.Entry(top, textvariable=self.psc_var, width=10).pack(side="left")

        # Barra pulsanti
        btns = ttk.Frame(self.root, padding=(8, 0))
        btns.pack(fill="x")
        self.btn_read = ttk.Button(btns, text="Leggi carta",
                                   command=self.on_read)
        self.btn_read.pack(side="left", padx=2)
        self.btn_load = ttk.Button(btns, text="Carica .bin",
                                   command=self.on_load)
        self.btn_load.pack(side="left", padx=2)
        self.btn_save = ttk.Button(btns, text="Salva .bin",
                                   command=self.on_save)
        self.btn_save.pack(side="left", padx=2)
        self.btn_write = ttk.Button(btns, text="Scrivi su carta",
                                    command=self.on_write)
        self.btn_write.pack(side="left", padx=2)
        self.btn_erase = ttk.Button(btns, text="Azzera carta (FF)",
                                    command=self.on_erase)
        self.btn_erase.pack(side="left", padx=2)

        # Info carta
        info = ttk.Frame(self.root, padding=(8, 4))
        info.pack(fill="x")
        self.atr_var = tk.StringVar(value="ATR: -")
        self.prot_var = tk.StringVar(value="Protezione: -")
        self.ec_var = tk.StringVar(value="Contatore PSC: -")
        ttk.Label(info, textvariable=self.atr_var).grid(
            row=0, column=0, sticky="w", padx=4)
        ttk.Label(info, textvariable=self.prot_var).grid(
            row=1, column=0, sticky="w", padx=4)
        ttk.Label(info, textvariable=self.ec_var).grid(
            row=2, column=0, sticky="w", padx=4)

        # Dump esadecimale
        ttk.Label(self.root, text="Memoria (256 byte):",
                  padding=(8, 2)).pack(anchor="w")
        self.hex = tk.Text(self.root, height=18, width=90,
                           font=("Consolas", 10), state="disabled")
        self.hex.pack(fill="both", expand=True, padx=8)

        # Log
        ttk.Label(self.root, text="Log:", padding=(8, 2)).pack(anchor="w")
        self.log = tk.Text(self.root, height=7, font=("Consolas", 9),
                           state="disabled", background="#111", foreground="#ddd")
        self.log.pack(fill="x", padx=8, pady=(0, 8))

        if not PYSCARD_OK:
            self._log("ERRORE: manca 'pyscard'. Installa con: pip install pyscard")
            self._log("Dettaglio: " + PYSCARD_ERR)

        self.render_hex()

    # ---------- Utilita' ----------
    def _log(self, msg):
        self.log.configure(state="normal")
        self.log.insert("end", msg + "\n")
        self.log.see("end")
        self.log.configure(state="disabled")

    def _set_busy(self, busy):
        self.busy = busy
        state = "disabled" if busy else "normal"
        for b in (self.btn_read, self.btn_load, self.btn_save,
                  self.btn_write, self.btn_erase):
            b.configure(state=state)

    def render_hex(self):
        lines = []
        for off in range(0, MEM_SIZE, 16):
            row = self.mem[off:off + 16]
            hexp = " ".join("%02X" % b for b in row)
            asc = "".join(chr(b) if 32 <= b < 127 else "." for b in row)
            lines.append("%04X  %-47s  |%s|" % (off, hexp, asc))
        self.hex.configure(state="normal")
        self.hex.delete("1.0", "end")
        self.hex.insert("1.0", "\n".join(lines))
        self.hex.configure(state="disabled")

    def refresh_readers(self):
        if not PYSCARD_OK:
            return
        try:
            rl = [str(r) for r in readers()]
        except Exception as e:                # noqa
            rl = []
            self._log("Errore elenco lettori: %s" % e)
        self.reader_cb["values"] = rl
        if rl:
            # Preferisci un ACR39/38 se presente
            idx = 0
            for i, name in enumerate(rl):
                if any(k in name.upper() for k in ("ACR39", "ACR38", "ACS")):
                    idx = i
                    break
            self.reader_cb.current(idx)
        else:
            self._log("Nessun lettore PC/SC rilevato.")

    def _get_reader(self):
        name = self.reader_cb.get()
        for r in readers():
            if str(r) == name:
                return r
        raise RuntimeError("Lettore non selezionato o non disponibile.")

    def _connect(self):
        conn = self._get_reader().createConnection()
        conn.connect()
        return conn

    @staticmethod
    def _sw_ok(sw1, sw2):
        return sw1 == 0x90 and sw2 == 0x00

    def _select(self, conn):
        _, s1, s2 = conn.transmit(
            [0xFF, 0xA4, 0x00, 0x00, 0x01, CARD_TYPE_SLE4442])
        if not self._sw_ok(s1, s2):
            raise RuntimeError("SELECT_CARD_TYPE rifiutato (SW=%02X%02X)"
                               % (s1, s2))

    # ---------- Operazioni in thread ----------
    def _run(self, fn):
        if self.busy:
            return
        self._set_busy(True)
        threading.Thread(target=self._wrap, args=(fn,), daemon=True).start()

    def _wrap(self, fn):
        try:
            fn()
        except NoCardException:
            self._log("ERRORE: nessuna carta inserita.")
        except CardConnectionException as e:
            self._log("ERRORE di connessione: %s" % e)
        except Exception as e:                # noqa
            self._log("ERRORE: %s" % e)
        finally:
            self.root.after(0, lambda: self._set_busy(False))

    # ---------- Leggi ----------
    def on_read(self):
        self._run(self._do_read)

    def _do_read(self):
        conn = self._connect()
        atr = conn.getATR()
        self.root.after(0, lambda: self.atr_var.set(
            "ATR: " + " ".join("%02X" % b for b in atr)))
        self._log("Connesso. ATR: " + " ".join("%02X" % b for b in atr))
        self._select(conn)

        mem = []
        for addr in range(0, MEM_SIZE, 16):
            data, s1, s2 = conn.transmit([0xFF, 0xB0, 0x00, addr, 16])
            if not self._sw_ok(s1, s2):
                raise RuntimeError("Lettura fallita a 0x%02X (SW=%02X%02X)"
                                   % (addr, s1, s2))
            mem.extend(data[:16])
        self.mem = mem[:MEM_SIZE]

        prot, p1, p2 = conn.transmit([0xFF, 0xB2, 0x00, 0x00, 0x04])
        if self._sw_ok(p1, p2):
            self.root.after(0, lambda: self.prot_var.set(
                "Protezione (primi 32 byte): "
                + " ".join("%02X" % b for b in prot)))
        sec, e1, e2 = conn.transmit([0xFF, 0xB1, 0x00, 0x00, 0x04])
        if self._sw_ok(e1, e2) and sec:
            ec = sec[0]
            rim = bin(ec).count("1")
            txt = "0x%02X" % ec
            if ec == 0x07:
                txt += " (pieno, 3 tentativi)"
            elif ec == 0x00:
                txt += " (BLOCCATA in scrittura)"
            else:
                txt += " (%d tentativi rimasti)" % rim
            self.root.after(0, lambda: self.ec_var.set("Contatore PSC: " + txt))
        conn.disconnect()
        self.root.after(0, self.render_hex)
        self._log("Lettura completata (256 byte).")

    # ---------- Carica / Salva file ----------
    def on_load(self):
        path = filedialog.askopenfilename(
            title="Carica dump .bin",
            filetypes=[("Dump binario", "*.bin"), ("Tutti i file", "*.*")])
        if not path:
            return
        try:
            with open(path, "rb") as f:
                data = list(f.read())
        except OSError as e:
            self._log("Errore apertura file: %s" % e)
            return
        if len(data) < MEM_SIZE:
            self._log("Il file ha %d byte, ne servono %d." % (len(data), MEM_SIZE))
            return
        self.mem = data[:MEM_SIZE]
        self.render_hex()
        self._log("Caricato: %s" % path)

    def on_save(self):
        path = filedialog.asksaveasfilename(
            title="Salva dump .bin", defaultextension=".bin",
            filetypes=[("Dump binario", "*.bin")])
        if not path:
            return
        try:
            with open(path, "wb") as f:
                f.write(bytes(self.mem))
            self._log("Salvato: %s" % path)
        except OSError as e:
            self._log("Errore salvataggio: %s" % e)

    # ---------- Scrivi ----------
    def on_write(self):
        if not messagebox.askyesno(
                "Conferma scrittura",
                "Scrivere i 256 byte attuali sulla carta inserita?\n\n"
                "Un PSC errato consuma un tentativo (3 errori = blocco "
                "scrittura definitivo)."):
            return
        self._run(lambda: self._do_write(self.mem))

    def on_erase(self):
        if not messagebox.askyesno(
                "Conferma azzeramento",
                "Scrivere TUTTI FF sulla carta (azzeramento)?"):
            return
        self._run(lambda: self._do_write([0xFF] * MEM_SIZE))

    def _do_write(self, data):
        psc = toBytes(self.psc_var.get().strip())
        if len(psc) != 3:
            raise RuntimeError("Il PSC deve essere di 3 byte (6 cifre esa).")
        conn = self._connect()
        self._select(conn)

        _, v1, v2 = conn.transmit([0xFF, 0x20, 0x00, 0x00, 0x03] + list(psc))
        if not (v1 == 0x90 and v2 == 0x07):
            if v1 == 0x90 and v2 == 0x00:
                conn.disconnect()
                raise RuntimeError("Carta BLOCCATA in scrittura (tentativi esauriti).")
            conn.disconnect()
            rim = bin(v2).count("1")
            raise RuntimeError("PSC ERRATO (SW=%02X%02X). Tentativi rimasti: %d. "
                               "Mi fermo per non bruciarne altri." % (v1, v2, rim))
        self._log("PSC corretto: scrittura sbloccata.")

        for addr in range(0, MEM_SIZE, 16):
            block = data[addr:addr + 16]
            apdu = [0xFF, 0xD0, 0x00, addr, len(block)] + block
            _, w1, w2 = conn.transmit(apdu)
            if not self._sw_ok(w1, w2):
                conn.disconnect()
                raise RuntimeError("Scrittura fallita a 0x%02X (SW=%02X%02X)"
                                   % (addr, w1, w2))
        self._log("Scrittura completata. Verifico...")

        # Rilettura e verifica
        back = []
        for addr in range(0, MEM_SIZE, 16):
            d, s1, s2 = conn.transmit([0xFF, 0xB0, 0x00, addr, 16])
            back.extend(d[:16])
        conn.disconnect()
        diffs = [i for i in range(MEM_SIZE) if back[i] != data[i]]
        self.mem = back[:MEM_SIZE]
        self.root.after(0, self.render_hex)
        if not diffs:
            self._log("OK: verifica superata, i 256 byte coincidono.")
            self.root.after(0, lambda: messagebox.showinfo(
                "Fatto", "Scrittura e verifica completate con successo."))
        else:
            self._log("ATTENZIONE: %d byte diversi dopo la scrittura." % len(diffs))
            self.root.after(0, lambda: messagebox.showwarning(
                "Verifica", "%d byte non coincidono (possibili byte protetti)."
                % len(diffs)))


def main():
    root = tk.Tk()
    SLE4442App(root)
    root.mainloop()


if __name__ == "__main__":
    main()
