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
    google      voci Gemini, si dirigono a parole, chiave in chiave-google.txt
    elevenlabs  massimo realismo, chiave in chiave-elevenlabs.txt
    openai      buona qualita' e regia recitativa, chiave in chiave-openai.txt

La chiave dei servizi a pagamento si incolla in un file di testo accanto a questo
script; in alternativa vale la solita variabile d'ambiente.
"""

import argparse
import asyncio
import base64
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
    "google": {"F": "Sulafat", "M": "Charon"},
}

# Google restituisce PCM grezzo, non MP3: quegli episodi escono in WAV.
FORMATO = {"edge": "mp3", "elevenlabs": "mp3", "openai": "mp3", "google": "wav"}

# Quante battute insieme: Google ha limiti di frequenza piu' stretti.
PARALLELE_PER_MOTORE = {"edge": 4, "elevenlabs": 3, "openai": 3, "google": 2}

MODELLI_GOOGLE = ["gemini-3.1-flash-tts-preview", "gemini-2.5-flash-preview-tts"]

# Le 30 voci Gemini, con il carattere dichiarato da Google.
VOCI_GOOGLE = [
    ("Zephyr", "brillante"), ("Puck", "vivace"), ("Charon", "informativa"),
    ("Kore", "decisa"), ("Fenrir", "eccitabile"), ("Leda", "giovane"),
    ("Orus", "decisa"), ("Aoede", "leggera"), ("Callirrhoe", "rilassata"),
    ("Autonoe", "brillante"), ("Enceladus", "sussurrata"), ("Iapetus", "nitida"),
    ("Umbriel", "rilassata"), ("Algieba", "morbida"), ("Despina", "morbida"),
    ("Erinome", "nitida"), ("Algenib", "roca"), ("Rasalgethi", "informativa"),
    ("Laomedeia", "vivace"), ("Achernar", "delicata"), ("Alnilam", "decisa"),
    ("Schedar", "regolare"), ("Gacrux", "matura"), ("Pulcherrima", "diretta"),
    ("Achird", "amichevole"), ("Zubenelgenubi", "informale"),
    ("Vindemiatrix", "gentile"), ("Sadachbia", "briosa"),
    ("Sadaltager", "competente"), ("Sulafat", "calda"),
]

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
    # Ogni motore ha nomi di voce suoi: "voci:" vale per tutti, "voci_google:"
    # (o _elevenlabs, _openai) ha la precedenza quando usi quel motore. Cosi' lo
    # stesso copione gira ovunque.
    dichiarate = {k.upper(): v for k, v in (meta.get("voci") or {}).items()}
    dichiarate.update({k.upper(): v
                       for k, v in (meta.get("voci_" + motore) or {}).items()})
    personaggi = []
    for elemento in elementi:
        if isinstance(elemento, Battuta) and elemento.chi not in personaggi:
            personaggi.append(elemento.chi)

    ripiego = VOCI_PREDEFINITE[motore]
    alternate = [ripiego["F"], ripiego["M"]]
    voci = {}
    for indice, chi in enumerate(personaggi):
        voci[chi] = dichiarate.get(chi) or alternate[indice % len(alternate)]

    if motore == "google":
        ammesse = {nome.lower(): nome for nome, _ in VOCI_GOOGLE}
        for chi, voce in voci.items():
            if voce.lower() not in ammesse:
                sostituta = alternate[list(voci).index(chi) % len(alternate)]
                print(f"[i] \"{voce}\" non e' una voce Google: per {chi} uso "
                      f"{sostituta}. L'elenco completo: --voci -m google")
                voci[chi] = sostituta
            else:
                voci[chi] = ammesse[voce.lower()]
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


FREQUENZA_PCM = 24000        # Gemini restituisce sempre 24 kHz, 16 bit, mono


def _solo_pcm(dati):
    """Toglie l'eventuale intestazione WAV, lasciando i campioni grezzi."""
    if dati[:4] == b"RIFF" and dati[8:12] == b"WAVE":
        i = 12
        while i + 8 <= len(dati):
            nome = dati[i:i + 4]
            misura = int.from_bytes(dati[i + 4:i + 8], "little")
            if nome == b"data":
                return dati[i + 8:i + 8 + misura]
            i += 8 + misura + (misura & 1)
    return dati


def monta_wav(pezzi, frequenza=FREQUENZA_PCM):
    """Unisce campioni PCM e silenzi, e ci mette sopra un'intestazione WAV."""
    campioni = bytearray()
    for tipo, valore in pezzi:
        if tipo == "pausa":
            if valore > 0:
                campioni += b"\x00\x00" * int(frequenza * valore / 1000)
        else:
            campioni += _solo_pcm(valore)

    if not campioni:
        raise SystemExit("Nessun audio ricevuto: impossibile montare l'episodio.")

    byte_al_secondo = frequenza * 2          # 16 bit mono = 2 byte per campione
    intestazione = (
        b"RIFF" + (36 + len(campioni)).to_bytes(4, "little") + b"WAVEfmt "
        + (16).to_bytes(4, "little")         # lunghezza del blocco fmt
        + (1).to_bytes(2, "little")          # PCM non compresso
        + (1).to_bytes(2, "little")          # un canale
        + frequenza.to_bytes(4, "little")
        + byte_al_secondo.to_bytes(4, "little")
        + (2).to_bytes(2, "little")          # allineamento di blocco
        + (16).to_bytes(2, "little")         # bit per campione
        + b"data" + len(campioni).to_bytes(4, "little")
    )
    return intestazione + bytes(campioni), len(campioni) / byte_al_secondo


# --------------------------------------------------------------------------
# Motori di sintesi vocale
# --------------------------------------------------------------------------

def _proxy():
    return os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")


# Servizi a pagamento: (variabile d'ambiente, file con la chiave, nome, dove si prende)
CHIAVI = {
    "elevenlabs": (
        "ELEVENLABS_API_KEY", "chiave-elevenlabs.txt", "ElevenLabs",
        "https://elevenlabs.io  ->  icona del profilo in alto a destra  ->  API keys",
    ),
    "openai": (
        "OPENAI_API_KEY", "chiave-openai.txt", "OpenAI",
        "https://platform.openai.com/api-keys",
    ),
    "google": (
        "GEMINI_API_KEY", "chiave-google.txt", "Google",
        "https://aistudio.google.com/apikey  ->  \"Create API key\"",
    ),
}


# Quando la chiave viene aggiunta a monte (credenziale API dell'ambiente, o un
# proxy aziendale), qui non ne serve nessuna e l'intestazione va omessa.
CHIAVE_ESTERNA = False


def _chiave(motore):
    """Trova la chiave del servizio: prima l'ambiente, poi il file accanto allo script."""
    if CHIAVE_ESTERNA:
        return None

    variabile, nome_file, servizio, dove = CHIAVI[motore]

    for nome in (variabile, "GOOGLE_API_KEY" if motore == "google" else variabile):
        dall_ambiente = (os.environ.get(nome) or "").strip()
        if dall_ambiente:
            return dall_ambiente

    cartella_script = Path(__file__).resolve().parent
    for cartella in (cartella_script, Path.cwd()):
        percorso = cartella / nome_file
        if not percorso.is_file():
            continue
        for riga in percorso.read_text(encoding="utf-8").splitlines():
            riga = riga.strip()
            if not riga or riga.startswith("#"):
                continue
            if "=" in riga:                    # tollera "ELEVENLABS_API_KEY=xxx"
                riga = riga.split("=", 1)[1].strip()
            return riga.strip("'\"")

    raise SystemExit(
        f"\nPer usare le voci {servizio} serve la tua chiave personale.\n\n"
        f"  1. Apri {dove}\n"
        f"  2. Copia la chiave.\n"
        f"  3. Incollala dentro a questo file (creandolo):\n"
        f"       {cartella_script / nome_file}\n\n"
        f"Il file resta sul tuo computer: e' gia' escluso da Git.\n"
        f"In Windows puoi anche fare doppio clic su CREA-PODCAST.cmd e scegliere\n"
        f"{servizio}: la chiave te la chiede lui e la salva al posto tuo.\n"
    )


# Gli ID voce di ElevenLabs sono 20 caratteri alfanumerici: tutto il resto e' un nome.
RE_ID_ELEVENLABS = re.compile(r"[A-Za-z0-9]{20}")


def _elenco_voci_elevenlabs(chiave):
    richiesta = urllib.request.Request(
        "https://api.elevenlabs.io/v1/voices",
        headers={"xi-api-key": chiave} if chiave else {},
    )
    with urllib.request.urlopen(richiesta, timeout=60) as risposta:
        return json.load(risposta).get("voices", [])


def risolvi_voci_elevenlabs(voci):
    """Permette di scrivere in 'voci:' il nome della voce invece del suo ID."""
    da_risolvere = {chi: v for chi, v in voci.items() if not RE_ID_ELEVENLABS.fullmatch(v)}
    if not da_risolvere:
        return voci

    disponibili = _elenco_voci_elevenlabs(_chiave("elevenlabs"))
    per_nome = {v["name"].strip().lower(): v["voice_id"] for v in disponibili}

    for chi, nome in da_risolvere.items():
        trovata = per_nome.get(nome.strip().lower())
        if not trovata:
            elenco = ", ".join(sorted(v["name"] for v in disponibili)) or "(nessuna)"
            raise SystemExit(
                f"\nVoce \"{nome}\" non trovata nel tuo account ElevenLabs.\n"
                f"Voci disponibili: {elenco}\n"
            )
        voci[chi] = trovata
    return voci


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


def _intestazioni(nome, valore):
    """Aggiunge l'intestazione di autenticazione solo se abbiamo una chiave."""
    intestazioni = {"Content-Type": "application/json"}
    if valore:
        intestazioni[nome] = valore
    return intestazioni


def _richiesta_http(url, corpo, intestazioni):
    richiesta = urllib.request.Request(url, data=corpo, headers=intestazioni, method="POST")
    with urllib.request.urlopen(richiesta, timeout=180) as risposta:
        return risposta.read()


async def _sintesi_elevenlabs(battuta, voce, globali):
    chiave = _chiave("elevenlabs")
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
        _richiesta_http, url, corpo, _intestazioni("xi-api-key", chiave),
    )


async def _sintesi_openai(battuta, voce, globali):
    chiave = _chiave("openai")
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
        _intestazioni("Authorization", f"Bearer {chiave}" if chiave else None),
    )


def _errore_http(errore):
    """Google e OpenAI spiegano il problema nel corpo della risposta: mostralo."""
    try:
        dettaglio = json.loads(errore.read().decode("utf-8", "replace"))
        messaggio = dettaglio.get("error", {}).get("message") or str(dettaglio)
    except Exception:
        messaggio = errore.reason
    return f"HTTP {errore.code}: {messaggio}"


def _chiamata_google(testo, voce, modello, chiave):
    corpo = json.dumps({
        "contents": [{"parts": [{"text": testo}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voce}}
            },
        },
    }).encode("utf-8")
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{modello}:generateContent")
    risposta = json.loads(_richiesta_http(
        url, corpo, _intestazioni("x-goog-api-key", chiave)
    ))
    try:
        parti = risposta["candidates"][0]["content"]["parts"]
        for parte in parti:
            if "inlineData" in parte:
                return base64.b64decode(parte["inlineData"]["data"])
    except (KeyError, IndexError):
        pass
    raise RuntimeError(f"risposta senza audio: {json.dumps(risposta)[:300]}")


async def _sintesi_google(battuta, voce, globali):
    chiave = _chiave("google")

    # Con Gemini il tono non si regola con dei numeri: si dice a parole.
    regia = battuta.opzioni.get("regia") or globali.get("regia")
    testo = f"{regia}: {battuta.testo}" if regia else battuta.testo

    richiesti = [globali["modello"]] if globali.get("modello") else MODELLI_GOOGLE
    ultimo = None
    for modello in richiesti:
        try:
            return await asyncio.to_thread(_chiamata_google, testo, voce, modello, chiave)
        except urllib.error.HTTPError as errore:
            ultimo = _errore_http(errore)
            if errore.code not in (400, 404):   # modello assente: prova il successivo
                raise RuntimeError(ultimo) from errore
    raise RuntimeError(f"nessun modello Gemini utilizzabile ({ultimo})")


MOTORI = {
    "edge": _sintesi_edge,
    "elevenlabs": _sintesi_elevenlabs,
    "openai": _sintesi_openai,
    "google": _sintesi_google,
}


async def sintetizza(elementi, voci, motore, globali, silenzioso=False):
    """Sintetizza tutte le battute (in parallelo) e restituisce i pezzi in ordine."""
    funzione = MOTORI[motore]
    battute = [(i, e) for i, e in enumerate(elementi) if isinstance(e, Battuta)]
    risultati = {}
    limite = asyncio.Semaphore(PARALLELE_PER_MOTORE.get(motore, RICHIESTE_PARALLELE))
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
        disponibili = _elenco_voci_elevenlabs(_chiave("elevenlabs"))
        print("Voci ElevenLabs del tuo account:\n")
        for voce in sorted(disponibili, key=lambda v: v["name"]):
            print(f"  {voce['name']:24} {voce.get('labels', {}).get('description', '')}")
        print("\nNel copione basta scrivere il nome, per esempio:  ANNA: "
              f"{disponibili[0]['name'] if disponibili else 'Sarah'}")
    elif motore == "google":
        print("Voci Google (Gemini), tutte utilizzabili in italiano:\n")
        for nome, carattere in VOCI_GOOGLE:
            print(f"  {nome:16} {carattere}")
        print("\nPer un monologo intenso: Algenib (roca), Sadaltager (competente),")
        print("Gacrux (matura), Charon (informativa). Il tono si regola con 'regia:'.")
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
    analizzatore.add_argument("--chiave-esterna", action="store_true",
                              help="non cercare nessuna chiave qui: la aggiunge "
                                   "l'ambiente (credenziale API) o un proxy")
    analizzatore.add_argument("--silenzioso", action="store_true",
                              help="non stampare l'avanzamento battuta per battuta")
    argomenti = analizzatore.parse_args()

    global CHIAVE_ESTERNA
    CHIAVE_ESTERNA = argomenti.chiave_esterna

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
    if argomenti.motore == "elevenlabs":
        voci = risolvi_voci_elevenlabs(voci)
    globali = {k: v for k, v in meta.items() if k != "voci"}

    formato = FORMATO[argomenti.motore]
    uscita = (Path(argomenti.out) if argomenti.out
              else percorso.with_suffix("." + formato))
    if uscita.suffix.lower() != "." + formato:
        print(f"[i] Il motore {argomenti.motore} produce {formato.upper()}: "
              f"salvo comunque in {uscita.name}, cambia estensione se il lettore protesta.")
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
    audio, durata = monta_wav(pezzi) if formato == "wav" else monta_mp3(pezzi)
    uscita.parent.mkdir(parents=True, exist_ok=True)
    uscita.write_bytes(audio)

    minuti, secondi = divmod(int(durata), 60)
    print(f"\nFatto: {uscita}  ({len(audio) / 1024:.0f} KB, circa {minuti}:{secondi:02d})")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
