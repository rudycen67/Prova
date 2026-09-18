#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
crea-podcast.py — trasforma un copione di testo in un episodio audio con voci neurali.

Uso tipico:
    python3 crea-podcast.py copione.md -o episodio.mp3

Il copione e' un semplice file di testo con le battute marcate dal nome di chi parla:

    ---
    titolo: Il mio episodio
    voci:
      ANNA: it-IT-IsabellaNeural
      MARCO: it-IT-DiegoNeural
    ---

    ANNA: Benvenuti alla prima puntata.
    MARCO: Oggi parliamo di una cosa che usi ogni giorno senza saperlo.
    [pausa 800]
    ANNA(rate=-6%): E la storia... e' piu' strana di quello che immagini.

Motori disponibili:
    edge        (predefinito) voci neurali Microsoft, gratuite, nessuna chiave
    elevenlabs  massimo realismo, richiede ELEVENLABS_API_KEY
    openai      buona qualita' e regia recitativa, richiede OPENAI_API_KEY
"""

import argparse
import asyncio
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

# --------------------------------------------------------------------------
# Impostazioni predefinite
# --------------------------------------------------------------------------

VOCI_PREDEFINITE = {
    "edge": {
        "F": "it-IT-IsabellaNeural",
        "M": "it-IT-DiegoNeural",
    },
    "elevenlabs": {"F": "EXAVITQu4vr4xnSDxMaL", "M": "onwK4e9ZLuTAKqWW03F9"},
    "openai": {"F": "shimmer", "M": "onyx"},
}

PAUSA_BATTUTE_MS = 350      # respiro fra una battuta e l'altra
PAUSA_PREDEFINITA_MS = 600  # valore di [pausa] senza numero
RICHIESTE_PARALLELE = 4     # quante battute sintetizzare insieme
TENTATIVI = 3               # ritentativi su errore di rete


# --------------------------------------------------------------------------
# Lettura del copione
# --------------------------------------------------------------------------

# Il nome di chi parla deve essere in MAIUSCOLO: cosi' un normale "Nota: ..."
# dentro al testo non viene scambiato per una battuta.
RE_BATTUTA = re.compile(
    r"^(?P<chi>[A-ZÀ-ÜŽ0-9][A-ZÀ-ÜŽ0-9 _'\.-]{0,23})"
    r"(?:\((?P<opzioni>[^)]*)\))?"
    r"\s*:\s*(?P<testo>.*)$"
)
RE_PAUSA = re.compile(r"^\[\s*pausa(?:\s+(?P<durata>\d+)\s*(?P<unita>ms|s)?)?\s*\]$", re.I)


class Battuta:
    """Una singola riga parlata."""

    def __init__(self, chi, testo, opzioni=None):
        self.chi = chi
        self.testo = testo
        self.opzioni = opzioni or {}

    def aggiungi(self, testo):
        self.testo = (self.testo + " " + testo).strip()


class Pausa:
    """Un silenzio fra due battute."""

    def __init__(self, ms):
        self.ms = ms


def _pulisci_testo(testo):
    """Toglie la formattazione markdown che le voci leggerebbero ad alta voce."""
    testo = re.sub(r"\*\*(.+?)\*\*", r"\1", testo)
    testo = re.sub(r"(?<!\w)[*_](.+?)[*_](?!\w)", r"\1", testo)
    testo = re.sub(r"`(.+?)`", r"\1", testo)
    return re.sub(r"\s+", " ", testo).strip()


def _leggi_intestazione(righe):
    """Legge il blocco --- ... --- in cima al copione. Niente dipendenze YAML."""
    meta = {"voci": {}}
    if not righe or righe[0].strip() != "---":
        return meta, righe

    chiave_annidata = None
    for i, riga in enumerate(righe[1:], start=1):
        if riga.strip() == "---":
            return meta, righe[i + 1:]
        if not riga.strip() or riga.lstrip().startswith("#"):
            continue

        rientrata = riga[:1].isspace()
        if ":" not in riga:
            continue
        chiave, _, valore = riga.partition(":")
        chiave = chiave.strip()
        valore = valore.strip()

        if rientrata and chiave_annidata:
            meta.setdefault(chiave_annidata, {})[chiave.upper()] = valore
        elif not valore:
            chiave_annidata = chiave.lower()
            meta.setdefault(chiave_annidata, {})
        else:
            chiave_annidata = None
            meta[chiave.lower()] = valore

    # Manca il --- di chiusura: trattiamo tutto come corpo.
    return {"voci": {}}, righe


def _leggi_opzioni(testo):
    """Interpreta ANNA(rate=-6%, pitch=+2Hz): ..."""
    opzioni = {}
    if not testo:
        return opzioni
    for pezzo in testo.split(","):
        if "=" not in pezzo:
            continue
        chiave, _, valore = pezzo.partition("=")
        opzioni[chiave.strip().lower()] = valore.strip()
    return opzioni


def leggi_copione(percorso):
    """Trasforma il file del copione in (metadati, elenco di Battuta/Pausa)."""
    righe = Path(percorso).read_text(encoding="utf-8").splitlines()
    meta, corpo = _leggi_intestazione(righe)

    elementi = []
    ultima = None

    for riga in corpo:
        nuda = riga.strip()

        if not nuda:
            ultima = None                      # riga vuota = fine della battuta
            continue
        if nuda.startswith("#") or nuda.startswith("//"):
            ultima = None                      # commento / titolo di sezione
            continue

        pausa = RE_PAUSA.match(nuda)
        if pausa:
            durata = int(pausa.group("durata") or PAUSA_PREDEFINITA_MS)
            if (pausa.group("unita") or "ms").lower() == "s":
                durata *= 1000
            elementi.append(Pausa(durata))
            ultima = None
            continue

        battuta = RE_BATTUTA.match(nuda)
        if battuta:
            testo = _pulisci_testo(battuta.group("testo"))
            ultima = Battuta(
                battuta.group("chi").strip().upper(),
                testo,
                _leggi_opzioni(battuta.group("opzioni")),
            )
            elementi.append(ultima)
            continue

        if ultima is not None:                 # continuazione della battuta sopra
            ultima.aggiungi(_pulisci_testo(nuda))
        else:
            raise SystemExit(
                f"Riga non riconosciuta nel copione (manca 'NOME:' davanti?):\n  {nuda}"
            )

    battute = [e for e in elementi if isinstance(e, Battuta) and e.testo]
    if not battute:
        raise SystemExit("Il copione non contiene battute. Serve almeno una riga 'NOME: testo'.")

    return meta, [e for e in elementi if not (isinstance(e, Battuta) and not e.testo)]


def assegna_voci(meta, elementi, motore):
    """Decide quale voce usa ogni personaggio, anche se il copione non lo dice."""
    dichiarate = {k.upper(): v for k, v in (meta.get("voci") or {}).items()}
    personaggi = []
    for elemento in elementi:
        if isinstance(elemento, Battuta) and elemento.chi not in personaggi:
            personaggi.append(elemento.chi)

    ripiego = VOCI_PREDEFINITE[motore]
    alternate = [ripiego["F"], ripiego["M"]]
    voci = {}
    for indice, chi in enumerate(personaggi):
        voci[chi] = dichiarate.get(chi) or alternate[indice % len(alternate)]
    return voci


# --------------------------------------------------------------------------
# Montaggio MP3 (senza ffmpeg: si incollano direttamente i frame)
# --------------------------------------------------------------------------

BITRATE_V1_L3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
BITRATE_V2_L3 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0]
FREQUENZE = {3: [44100, 48000, 32000], 2: [22050, 24000, 16000], 0: [11025, 12000, 8000]}


def _togli_tag(dati):
    """Rimuove ID3v2 in testa e ID3v1 in coda: restano solo i frame audio."""
    inizio = 0
    if dati[:3] == b"ID3" and len(dati) > 10:
        misura = ((dati[6] & 0x7F) << 21) | ((dati[7] & 0x7F) << 14) | \
                 ((dati[8] & 0x7F) << 7) | (dati[9] & 0x7F)
        inizio = 10 + misura
        if dati[5] & 0x10:
            inizio += 10                      # footer facoltativo
    fine = len(dati)
    if fine >= 128 and dati[fine - 128:fine - 125] == b"TAG":
        fine -= 128
    return dati[inizio:fine]


def _leggi_frame(dati, i):
    """Restituisce (lunghezza, campioni, frequenza) del frame MP3 che inizia in i."""
    if i + 4 > len(dati) or dati[i] != 0xFF or (dati[i + 1] & 0xE0) != 0xE0:
        return None
    versione = (dati[i + 1] >> 3) & 0x03
    livello = (dati[i + 1] >> 1) & 0x03
    indice_bitrate = (dati[i + 2] >> 4) & 0x0F
    indice_freq = (dati[i + 2] >> 2) & 0x03
    riempimento = (dati[i + 2] >> 1) & 0x01

    if versione == 1 or livello != 1 or indice_bitrate in (0, 15) or indice_freq == 3:
        return None                            # non e' un MP3 (Layer III) valido

    bitrate = (BITRATE_V1_L3 if versione == 3 else BITRATE_V2_L3)[indice_bitrate] * 1000
    frequenza = FREQUENZE[versione][indice_freq]
    campioni = 1152 if versione == 3 else 576
    lunghezza = (campioni // 8) * bitrate // frequenza + riempimento
    return lunghezza, campioni, frequenza


def _salta_intestazione_xing(dati):
    """Il primo frame puo' essere un indice Xing/Info: va tenuto solo una volta."""
    frame = _leggi_frame(dati, 0)
    if not frame:
        return dati
    lunghezza = frame[0]
    if b"Xing" in dati[:lunghezza] or b"Info" in dati[:lunghezza]:
        return dati[lunghezza:]
    return dati


def _frame_di_silenzio(riferimento):
    """Costruisce un frame muto identico per formato a quello di riferimento."""
    frame = _leggi_frame(riferimento, 0)
    if not frame:
        return None, 0
    lunghezza, campioni, frequenza = frame
    intestazione = bytearray(riferimento[:4])
    intestazione[1] |= 0x01                    # niente CRC nel frame che generiamo
    intestazione[2] &= ~0x02 & 0xFF            # niente byte di riempimento
    lunghezza_senza_padding = lunghezza - ((riferimento[2] >> 1) & 0x01)
    # Dati tutti a zero: il decoder legge "nessun contenuto" e quindi silenzio.
    return bytes(intestazione) + b"\x00" * (lunghezza_senza_padding - 4), \
        campioni / frequenza * 1000


def monta_mp3(pezzi):
    """Unisce audio e silenzi in un unico MP3. pezzi: ('audio', dati) / ('pausa', ms)."""
    riferimento = None
    for tipo, valore in pezzi:
        if tipo == "audio":
            puliti = _togli_tag(valore)
            if _leggi_frame(puliti, 0):
                riferimento = puliti
                break
    if riferimento is None:
        raise SystemExit("L'audio ricevuto non e' un MP3 valido: impossibile montare l'episodio.")

    silenzio, durata_frame = _frame_di_silenzio(riferimento)
    uscita = bytearray()
    primo = True
    durata_totale = 0.0

    for tipo, valore in pezzi:
        if tipo == "pausa":
            if silenzio and valore > 0:
                quanti = max(1, round(valore / durata_frame))
                uscita += silenzio * quanti
                durata_totale += quanti * durata_frame / 1000
            continue

        dati = _togli_tag(valore)
        if not primo:
            dati = _salta_intestazione_xing(dati)
        uscita += dati
        primo = False

        # Durata stimata scorrendo i frame, per il riepilogo finale.
        i = 0
        while True:
            frame = _leggi_frame(dati, i)
            if not frame:
                break
            durata_totale += frame[1] / frame[2]
            i += frame[0]

    return bytes(uscita), durata_totale


# --------------------------------------------------------------------------
# Motori di sintesi vocale
# --------------------------------------------------------------------------

def _proxy():
    return os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")


def _normalizza_percentuale(valore, predefinito="+0%"):
    if not valore:
        return predefinito
    valore = valore.strip()
    if not valore.startswith(("+", "-")):
        valore = "+" + valore
    return valore


async def _sintesi_edge(battuta, voce, globali):
    import edge_tts

    rate = _normalizza_percentuale(battuta.opzioni.get("rate") or globali.get("velocita"))
    volume = _normalizza_percentuale(battuta.opzioni.get("volume") or globali.get("volume"))
    pitch = battuta.opzioni.get("pitch") or globali.get("tono") or "+0Hz"
    if not pitch.startswith(("+", "-")):
        pitch = "+" + pitch

    comunicazione = edge_tts.Communicate(
        battuta.testo, voce, rate=rate, volume=volume, pitch=pitch, proxy=_proxy()
    )
    audio = bytearray()
    async for blocco in comunicazione.stream():
        if blocco["type"] == "audio":
            audio += blocco["data"]
    if not audio:
        raise RuntimeError(f"nessun audio restituito per la voce {voce}")
    return bytes(audio)


def _richiesta_http(url, corpo, intestazioni):
    richiesta = urllib.request.Request(url, data=corpo, headers=intestazioni, method="POST")
    with urllib.request.urlopen(richiesta, timeout=180) as risposta:
        return risposta.read()


async def _sintesi_elevenlabs(battuta, voce, globali):
    chiave = os.environ.get("ELEVENLABS_API_KEY")
    if not chiave:
        raise SystemExit("Manca ELEVENLABS_API_KEY nell'ambiente.")
    corpo = json.dumps({
        "text": battuta.testo,
        "model_id": globali.get("modello") or "eleven_multilingual_v2",
        "voice_settings": {
            "stability": float(battuta.opzioni.get("stability", 0.45)),
            "similarity_boost": float(battuta.opzioni.get("similarity", 0.8)),
            "style": float(battuta.opzioni.get("style", 0.35)),
            "use_speaker_boost": True,
        },
    }).encode("utf-8")
    url = (f"https://api.elevenlabs.io/v1/text-to-speech/{voce}"
           f"?output_format=mp3_44100_128")
    return await asyncio.to_thread(
        _richiesta_http, url, corpo,
        {"xi-api-key": chiave, "Content-Type": "application/json"},
    )


async def _sintesi_openai(battuta, voce, globali):
    chiave = os.environ.get("OPENAI_API_KEY")
    if not chiave:
        raise SystemExit("Manca OPENAI_API_KEY nell'ambiente.")
    payload = {
        "model": globali.get("modello") or "gpt-4o-mini-tts",
        "voice": voce,
        "input": battuta.testo,
        "response_format": "mp3",
    }
    regia = battuta.opzioni.get("regia") or globali.get("regia")
    if regia:
        payload["instructions"] = regia
    return await asyncio.to_thread(
        _richiesta_http, "https://api.openai.com/v1/audio/speech",
        json.dumps(payload).encode("utf-8"),
        {"Authorization": f"Bearer {chiave}", "Content-Type": "application/json"},
    )


MOTORI = {
    "edge": _sintesi_edge,
    "elevenlabs": _sintesi_elevenlabs,
    "openai": _sintesi_openai,
}


async def sintetizza(elementi, voci, motore, globali, silenzioso=False):
    """Sintetizza tutte le battute (in parallelo) e restituisce i pezzi in ordine."""
    funzione = MOTORI[motore]
    battute = [(i, e) for i, e in enumerate(elementi) if isinstance(e, Battuta)]
    risultati = {}
    limite = asyncio.Semaphore(RICHIESTE_PARALLELE)
    fatte = 0

    async def lavora(indice, battuta):
        nonlocal fatte
        async with limite:
            ultimo_errore = None
            for tentativo in range(1, TENTATIVI + 1):
                try:
                    risultati[indice] = await funzione(battuta, voci[battuta.chi], globali)
                    break
                except (urllib.error.URLError, RuntimeError, OSError) as errore:
                    ultimo_errore = errore
                    if tentativo < TENTATIVI:
                        await asyncio.sleep(2 ** tentativo)
            else:
                raise SystemExit(f"Sintesi fallita per la battuta di {battuta.chi}: {ultimo_errore}")
            fatte += 1
            if not silenzioso:
                print(f"  [{fatte}/{len(battute)}] {battuta.chi}: {battuta.testo[:58]}...",
                      flush=True)

    await asyncio.gather(*(lavora(i, b) for i, b in battute))

    pezzi = []
    for indice, elemento in enumerate(elementi):
        if isinstance(elemento, Pausa):
            pezzi.append(("pausa", elemento.ms))
        else:
            pezzi.append(("audio", risultati[indice]))
            pezzi.append(("pausa", int(globali.get("pausa_battute", PAUSA_BATTUTE_MS))))
    return pezzi


async def elenca_voci(motore):
    if motore == "edge":
        import edge_tts
        voci = await edge_tts.list_voices(proxy=_proxy())
        italiane = [v for v in voci if v["Locale"].startswith("it-")]
        print("Voci italiane disponibili (motore edge, gratuite):\n")
        for voce in sorted(italiane, key=lambda v: v["ShortName"]):
            genere = "femminile" if voce["Gender"] == "Female" else "maschile"
            print(f"  {voce['ShortName']:38} {genere}")
        print(f"\nTotale voci in tutte le lingue: {len(voci)}")
    elif motore == "elevenlabs":
        chiave = os.environ.get("ELEVENLABS_API_KEY")
        if not chiave:
            raise SystemExit("Manca ELEVENLABS_API_KEY nell'ambiente.")
        richiesta = urllib.request.Request(
            "https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": chiave}
        )
        with urllib.request.urlopen(richiesta, timeout=60) as risposta:
            dati = json.load(risposta)
        print("Voci ElevenLabs del tuo account:\n")
        for voce in dati.get("voices", []):
            print(f"  {voce['voice_id']:26} {voce['name']}")
    else:
        print("Voci OpenAI: alloy, ash, ballad, coral, echo, fable, nova, onyx, sage, shimmer")


# --------------------------------------------------------------------------
# Avvio
# --------------------------------------------------------------------------

def main():
    analizzatore = argparse.ArgumentParser(
        description="Trasforma un copione di testo in un episodio podcast con voci neurali.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Esempio:  python3 crea-podcast.py esempi/esempio-rfid.md -o episodio.mp3",
    )
    analizzatore.add_argument("copione", nargs="?", help="file del copione (.md o .txt)")
    analizzatore.add_argument("-o", "--out", help="file MP3 da creare")
    analizzatore.add_argument("-m", "--motore", default="edge", choices=sorted(MOTORI),
                              help="motore vocale (predefinito: edge)")
    analizzatore.add_argument("--voci", action="store_true",
                              help="elenca le voci disponibili ed esce")
    analizzatore.add_argument("--silenzioso", action="store_true",
                              help="non stampare l'avanzamento battuta per battuta")
    argomenti = analizzatore.parse_args()

    if argomenti.voci:
        asyncio.run(elenca_voci(argomenti.motore))
        return

    if not argomenti.copione:
        analizzatore.error("serve il file del copione (oppure --voci)")

    percorso = Path(argomenti.copione)
    if not percorso.is_file():
        raise SystemExit(f"Copione non trovato: {percorso}")

    if argomenti.motore == "edge":
        try:
            import edge_tts  # noqa: F401
        except ImportError:
            raise SystemExit("Manca il modulo edge-tts. Installalo con:  pip install edge-tts")

    meta, elementi = leggi_copione(percorso)
    voci = assegna_voci(meta, elementi, argomenti.motore)
    globali = {k: v for k, v in meta.items() if k != "voci"}

    uscita = Path(argomenti.out) if argomenti.out else percorso.with_suffix(".mp3")
    titolo = meta.get("titolo") or percorso.stem
    battute = [e for e in elementi if isinstance(e, Battuta)]
    caratteri = sum(len(e.testo) for e in battute)

    print(f"\nEpisodio : {titolo}")
    print(f"Motore   : {argomenti.motore}")
    print(f"Battute  : {len(battute)}  ({caratteri} caratteri)")
    for chi, voce in voci.items():
        print(f"  {chi:<12} -> {voce}")
    print()

    pezzi = asyncio.run(sintetizza(elementi, voci, argomenti.motore, globali,
                                   argomenti.silenzioso))
    audio, durata = monta_mp3(pezzi)
    uscita.parent.mkdir(parents=True, exist_ok=True)
    uscita.write_bytes(audio)

    minuti, secondi = divmod(int(durata), 60)
    print(f"\nFatto: {uscita}  ({len(audio) / 1024:.0f} KB, circa {minuti}:{secondi:02d})")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
