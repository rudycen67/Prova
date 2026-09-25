#!/usr/bin/env python3
"""
genera-voce.py
--------------
Client per l'API TTS-RVC: invia un testo e salva l'audio .wav con la voce RVC.
Usa solo la libreria standard (nessun "pip install" necessario): funziona sia
in Ubuntu/WSL sia in Windows, con il server avviato da voce/avvia-server.sh.

Esempi:
  python3 voce/genera-voce.py --elenco
  python3 voce/genera-voce.py -s speaker3 "Ciao! Benvenuto nel mondo."
  python3 voce/genera-voce.py -s mia_voce -f testo.txt -o saluto.wav --speed 1.2
"""
import argparse
import json
import sys
import time
import urllib.error
import urllib.request


def richiesta(url, dati=None, timeout=600):
    corpo = json.dumps(dati).encode("utf-8") if dati is not None else None
    req = urllib.request.Request(
        url,
        data=corpo,
        headers={"Content-Type": "application/json"} if corpo else {},
        method="POST" if corpo else "GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as risposta:
            return risposta.read()
    except urllib.error.HTTPError as e:
        dettaglio = e.read().decode("utf-8", "replace")
        try:
            dettaglio = json.loads(dettaglio).get("detail", dettaglio)
        except (ValueError, AttributeError):
            pass
        sys.exit(f"Errore dal server (HTTP {e.code}): {dettaglio}")
    except urllib.error.URLError as e:
        sys.exit(f"Server non raggiungibile su {url} ({e.reason}).\n"
                 "Avvialo con:  bash voce/avvia-server.sh")


def main():
    p = argparse.ArgumentParser(description="Sintesi vocale Coqui TTS + RVC")
    p.add_argument("testo", nargs="?", help="testo da pronunciare")
    p.add_argument("-f", "--file", help="legge il testo da un file .txt (UTF-8)")
    p.add_argument("-s", "--speaker", help="nome della voce RVC (cartella in models/)")
    p.add_argument("-o", "--output", default="voce_generata.wav", help="file .wav di uscita")
    p.add_argument("--speed", type=float, default=1.0, help="velocita' (1.0 - 2.0)")
    p.add_argument("--emotion", help="solo per modelli che la supportano: con i modelli "
                                     "VITS standard lasciala vuota, altrimenti la richiesta fallisce")
    p.add_argument("--url", default="http://127.0.0.1:8000", help="indirizzo del server")
    p.add_argument("--elenco", action="store_true", help="mostra le voci RVC disponibili")
    a = p.parse_args()
    base = a.url.rstrip("/")

    if a.elenco:
        # r=".*" limita l'elenco ai modelli RVC (senza le centinaia di voci Bark).
        voci = json.loads(richiesta(f"{base}/speakers/?r=.*"))
        print("Voci RVC disponibili:")
        for v in voci:
            print(f"  - {v}")
        return

    if a.file:
        with open(a.file, encoding="utf-8") as fh:
            testo = fh.read()
    else:
        testo = a.testo
    if not testo or not testo.strip():
        p.error("specifica un testo oppure --file")
    if not a.speaker:
        p.error("specifica la voce con -s/--speaker (vedi --elenco)")
    if not 1.0 <= a.speed <= 2.0:
        p.error("--speed deve essere tra 1.0 e 2.0")

    dati = {"speaker_name": a.speaker, "input_text": testo, "speed": a.speed}
    if a.emotion:
        dati["emotion"] = a.emotion

    print(f"==> Genero l'audio con la voce '{a.speaker}'... (la prima volta e' lento)")
    t0 = time.time()
    # Lo slash finale evita il redirect 307 di FastAPI su /generate
    audio = richiesta(f"{base}/generate/", dati)
    with open(a.output, "wb") as fh:
        fh.write(audio)
    print(f"==> Salvato: {a.output}  ({len(audio) // 1024} KB, {time.time() - t0:.1f} s)")


if __name__ == "__main__":
    main()
