# PASSAGGIO DI CONSEGNE – Integrazione antifurto Bentel KYO 32 in Home Assistant tramite modulo Marss IP Controller

**Nome della conversazione**: "Integrazione Centrale Bentel Kyo in Home Assistant via Socat" (sessione Claude Code: https://claude.ai/code/session_014Vbqn6j6qMpfs1BZ5enW6p)
**Periodo**: 28 ottobre – 21 novembre 2026
**Repository GitHub con tutto il codice e la guida**: https://github.com/rudycen67/Prova — branch `claude/new-session-33hkm7` (NON ancora unito su `main`)
**Utente**: Marco (account GitHub `rudycen67`). Lingua: italiano. Scrive spesso in maiuscolo e con errori di battitura: è normale, non correggerlo.

---

## 0. ISTRUZIONI PER L'INTELLIGENZA ARTIFICIALE CHE RIPRENDE IL LAVORO

1. **Parla italiano**, con frasi brevi e passaggi numerati. L'utente non è un tecnico: preferisce la **GUI** (interfaccia grafica) ed evita il terminale. Quando serve un comando, dagli UNA riga sola da copiare/incollare e digli dove (PuTTY oppure "Terminal" di Home Assistant).
2. L'utente manda **screenshot e foto**: chiediglieli e usali. Quando devi indicare un morsetto o un pulsante, descrivi la posizione in modo inequivocabile ("quarta vite dall'alto, quella con il filo rosso") oppure, se puoi, restituisci la sua foto con un cerchio.
3. **Sicurezza elettrica, regola assoluta**: sul modulo Marss, gli ingressi IN1-IN4 sono ad alta impedenza e possono toccare punti a 12 V senza danni; il morsetto **GND del Marss NON va MAI collegato a un punto che possa andare a +12 V** (è già saltato un fusibile da 5 A per questo, vedi §6). Prima di ogni collegamento nuovo chiedi una misura con il tester (volt continui, nero su un morsetto "−" della KYO).
4. Prima di toccare l'impianto: **allarme disinserito**, tastiera a portata di mano con il codice utente. L'inserimento dalla zona chiave è immediato: finestre aperte o movimento fanno scattare subito la sirena.
5. Non far **riavviare il Raspberry togliendo la spina**: corrompe la SD (è già successo, l'utente ha dovuto ripristinare l'immagine della SD). Riavviare sempre da Impostazioni → Sistema → icona accensione.
6. Non proporre di nuovo soluzioni già scartate (vedi §5 "Strade scartate"), e non far ripetere lavori già fatti (§4).
7. Se l'utente chiede "dove" o "quale", rispondi con un riferimento visivo alla foto/schermata, non con un paragrafo.

---

## 1. OBIETTIVO DELL'UTENTE

Controllare l'antifurto di casa dall'app sul telefono (Android e iPhone), anche da fuori casa:
- vedere se l'impianto è **inserito**;
- ricevere una **notifica sonora quando scatta l'allarme**;
- **inserire e disinserire** da remoto.

Anni fa lo faceva con un Raspberry Pi + una schedina relè e un'app, che ha smesso di funzionare perché non si collegava più da remoto.

---

## 2. HARDWARE E RETE (tutto verificato sul campo)

| Elemento | Dettagli |
| --- | --- |
| Centrale antifurto | **Bentel KYO 32** (scheda "OK32 2.13 KYO32"), in scatola con etichetta KYO8M. Combinatore telefonico vocale **NC2/VOX** a fianco (l'utente ha deciso di TENERLO). Espansione **M-IN/OUT** (MINOUT 1.0) in scatola separata, zone T1-T4 usate, T5-T6 libere, tamper bloccato con fascetta (lasciare così). |
| Modulo IP | **Marss IP Controller IPC-3004** (scheda v1.3_102012, MAC 00:04:A3:BF:0E:6C), 4 ingressi + 4 uscite (2 relè + 2 open collector). IP **192.168.1.249**. Web server integrato su porta **443** in **SSLv3 con RC4** (nessun browser moderno lo apre). Porta 26501 = protocollo dell'app Marss (non HTTP). Credenziali web: **admin / marss**. Codice attivazione uscite: **123456**. Alimentato dalla centrale (il suo GND è il negativo della centrale). |
| Home Assistant | Home Assistant OS 18.3 su **Raspberry Pi 3** (aarch64). Utente HA: **marco**. IP era 192.168.1.13, poi il router gli ha dato 192.168.1.12: va impostato **IP statico 192.168.1.13** (Impostazioni → Sistema → Rete) — DA VERIFICARE se fatto. Accesso web: `http://192.168.1.13:8123` (o `http://homeassistant.local:8123`). |
| Add-on installati | File editor; Terminal & SSH (porta 22 attiva, password scelta dall'utente, utente `root`, usato con PuTTY); **Bentel Socat Bridge 2.1.1** (nostro, vedi §3). |
| PC dell'utente | Windows 11, IP 192.168.1.3, PuTTY installato, browser Chrome/Firefox. Ha un **tester** (multimetro). |
| Router | 192.168.1.254 secondo un foglietto dell'installatore (verificare). |

### Morsettiera del Marss (letta dalla serigrafia)
- In alto a sinistra, 3 viti: alimentazione (+12 V rosso, negativo blu, già cablati).
- A sinistra, 8 viti dall'alto: **Tamper, Tamper** (fili rossi, occupati), **IN1, GND, IN2, IN3, GND, IN4**.
- A destra in alto, 2 viti `+12V`: uscita "OC Life" (non usata).
- A destra al centro, 3 viti `OC1 +12V OC2`: uscite 3 e 4 (open collector).
- In basso a destra, 6 viti: `Relay 2` (tre viti sopra) e **`Relay 1`** (tre viti sotto: la centrale è il comune C, le esterne NO/NC).

### Morsettiera destra della KYO 32 (dall'alto)
31-30 AC (gialli), 29 RED, 28 BLK, 27 YEL, 26 GRN (bus tastiere), **25 O3** (libero), **24 O2** (libero), **23 O1** (filo giallo → va alla schedina relè dell'installatore; O1 è programmato come **"impianto inserito"**), **22 +B** (+12 V, rosso), poi il **relè di allarme**: **COM** (rosso, +12 V), **NO** (rosso, +12 V durante l'allarme; da qui anche un filo al "CEN" della schedina), **NC** (filo verde grosso, sirena). Uscite O1-O3 = open collector (danno solo negativo, sicure per gli ingressi del Marss).

### Schedina relè dell'installatore (dentro la centrale, morsetti + − CEN NA NC COM− COM+)
Alimentata/comandata dal relè di allarme della KYO (CEN ← NO), serve al combinatore. **NON USARLA**: le sue misure sono incoerenti e collegare CEN al GND del Marss ha fatto saltare il fusibile da 5 A della centrale (sostituito, centrale OK).

### Zona chiave
Due fili liberi (uno bianco, uno rosso) vicino al Marss, portati fuori dall'installatore per il vecchio Raspberry: toccati tra loro **inseriscono/disinseriscono** l'impianto (zona "Commutazione"). Sono il comando.

---

## 3. SOFTWARE REALIZZATO

### 3.1 Add-on Home Assistant "Bentel Socat Bridge" (repo `rudycen67/Prova`, cartella `bentel_socat/`, `repository.yaml` alla radice)
- Versione attuale **2.1.1**. Installato da: Impostazioni → Applicazioni → Installa applicazione → ⋮ → Archivi → `https://github.com/rudycen67/Prova#claude/new-session-33hkm7`.
- Cosa fa: compila OpenSSL 1.1.1w con **SSLv3** e cifrari deboli riabilitati + socat 1.8.0.3 (`/usr/local/bin/socat-ssl3`); **nginx** sulla porta 26501 accoda le richieste dei browser (il Marss regge UNA connessione alla volta) e le passa a socat (127.0.0.1:26502, `max-children=1`) che apre la connessione SSLv3 verso `192.168.1.249:443`. Risultato: la pagina del Marss si apre in HTTP normale su **`http://192.168.1.13:26501/protect/index.htm`** (admin/marss). Da Home Assistant l'add-on è raggiungibile col nome interno **`http://92d7005e-bentel-socat:26501`**.
- Opzioni: `bentel_host` 192.168.1.249, `bentel_port` **443**, `tls_mode` **ssl3**, `verbose` true. Attivare "Esegui dall'avvio" e "Sistema di controllo e sorveglianza".
- Build sul Pi 3: 15-30 minuti (compila OpenSSL). Dockerfile pinned su `ghcr.io/home-assistant/base:3.24`, `init: false`.
- Problema noto: **dopo ogni allarme il web server del Marss resta bloccato** (calo di tensione quando parte la sirena). Rimedio: riavviare l'add-on (o togliere/ridare alimentazione al Marss). L'automazione `antifurto_riavvia_ponte_se_bloccato` lo fa da sola.

### 3.2 Pagina web del Marss: cosa usa
- Stato: `GET /protect/status.xml` → `ledi1..8` (1 = spento, **2 = attivo/rosso**, 3 = giallo), `ledo1..8` (1 = uscita attiva), `ver_pass` (1 = aspetta il codice), `errCode`, `msgTampCh0..8`.
- Comando uscita: `GET /protect/buttons.cgi?button=N`, poi se serve `POST /protect/index.htm` con `password=123456`; `annulla.cgi?butt=0` annulla. Le uscite sono già "senza codice". HTTP Basic auth admin/marss.
- Input Configuration: tipo ingressi impostato su **Normally open** (vale per tutti e 4). Output Configuration: da impostare **temporizzazione 2 s sull'uscita 1** (DA VERIFICARE se fatto).

### 3.3 Configurazione Home Assistant (file completi in `docs/homeassistant/`)
- `configuration.yaml`: sensori `rest` (binary_sensor **Antifurto inserito** = ledi1==2, **Antifurto allarme in corso** = ledi2==2, tamper), `rest_command` (premi uscita, invia codice), **`alarm_control_panel` template "Antifurto"** (stati disarmed/armed_away/triggered; arm/disarm chiamano `script.antifurto_premi_uscita_1` solo se coerenti con lo stato).
- `scripts.yaml`: `antifurto_premi_uscita_1` (buttons.cgi?button=1 + codice), `antifurto_riavvia_ponte` (hassio.addon_restart 92d7005e_bentel_socat).
- `automations.yaml`: notifica ALLARME (critica, suona anche in silenzioso), notifica inserito/disinserito, riavvio del ponte se il sensore resta `unavailable` 3 minuti. Contengono il segnaposto **`NOME_TELEFONO`** da sostituire con il nome del servizio `notify.mobile_app_...` (Strumenti per sviluppatori → Azioni → cercare "mobile_app").
- **Stato attuale**: l'utente ha ricevuto i tre file completi da incollare al posto di tutto; NON è confermato che li abbia già incollati. Prima di quelli era attiva una versione precedente (sensori "Antifurto ingresso 1-4", 4 script "premi uscita 1-4", indirizzo `http://192.168.1.13:26501`).

---

## 4. LAVORI GIÀ FATTI E VERIFICATI (non rifare)
1. Diagnosi del problema originale (add-on locale in /config invece di /addons) → risolto con repository esterno di add-on.
2. Scoperta che il dispositivo .249 è un Marss (non la Bentel) e che parla solo SSLv3 → add-on con OpenSSL custom, funzionante (handshake SSLv3/RC4-MD5 confermato nei log).
3. Pagina Marss aperta nel browser, login OK, status.xml letto da Home Assistant (sensori RESTful comparsi).
4. Ingressi del Marss impostati "Normally open"; prova del filo: GND+IN2 → in2 rosso (ingresso sano anche dopo il corto).
5. Uscita 1 del Marss comandabile da PuTTY (`buttons.cgi?button=1` → `ledo1` 1/0) e da Home Assistant.
6. **in1 = "impianto inserito" già cablato** (filo giallo da O1/23 della KYO a IN1): quando si inserisce dalla tastiera in1 diventa rosso.
7. Prove per "allarme in corso": IN2 su NC → nessun cambio; IN2 su NO → nessun cambio (NO porta +12 V in allarme, l'ingresso non lo legge). Conclusione: serve un modulo relè.
8. Fusibile 5 A della KYO saltato (per CEN→GND) e **sostituito**: centrale funzionante.
9. Raspberry ripristinato da immagine SD dopo che sembrava irraggiungibile (in realtà l'IP era cambiato in .12): tutto tornato come prima.
10. Repository GitHub con add-on, guida (`docs/home-assistant-bentel-socat.md`), esempio HA, schema cablaggio, questo documento.

## 5. STRADE SCARTATE (non riproporre)
- Integrazioni HA esistenti per Bentel Kyo: non esistono (solo espkyogate via seriale ed un'integrazione per Absoluta, porte 3064/3062 chiuse sulla KYO).
- Usare la schedina relè dell'installatore (CEN/NA/COM): incoerente e pericolosa, già causato un corto. Il combinatore va lasciato com'è.
- Programmare O2/O1 della KYO: richiede il **codice installatore**, che l'utente NON ha. Resta l'alternativa se si vuole lo stato "allarme" senza modulo relè (l'installatore programma O2 = "Allarme Area 1" → IN2 sul 24).
- Usare il bus LAN per leggere l'allarme: impossibile.

## 6bis. AGGIORNAMENTO 21 NOVEMBRE 2026 (verificato dall'utente)
- **Comando OK**: la zona chiave e' sul Relay 1 del Marss, temporizzazione 2 s sull'uscita 1. La centrale commuta con **DUE impulsi da 2 s** (sia per inserire sia per disinserire): lo script `antifurto_premi_uscita_1` manda due impulsi a 4 s di distanza.
- **in1 = inserito OK** (rosso inserito, verde disinserito). **in2 = allarme in corso OK**: il rele' 12 V e' montato (bobina tra NO del rele' di allarme della KYO e 28 BLK; contatto su IN2/GND del Marss) e in2 diventa rosso mentre suona.
- L'IP del Raspberry e' cambiato ancora (ora 192.168.1.114): **impostare l'IP statico** resta il primo punto.
- Richiesta dell'utente: "app" Android e iPhone eleganti, con **sirena sul telefono** quando scatta l'allarme, in qualsiasi stato del telefono. Soluzione: app ufficiale Home Assistant + plancia `docs/homeassistant/plancia-antifurto.yaml` + automazione `antifurto_sirena_allarme` (notifica critica iOS con suono a volume 1.0; Android canale `alarm_stream` + TTS `alarm_stream_max`, ripetuta ogni 30 s finche' suona, pulsanti "Disinserisci" e "Apri"). File completi aggiornati in `docs/homeassistant/`. Segnaposto da sostituire: `NOME_ANDROID`, `NOME_IPHONE`.
- Per ricevere le notifiche fuori casa NON serve Nabu Casa (passano dai server push di Home Assistant); per aprire la plancia o premere "Disinserisci" da fuori casa serve l'accesso remoto (Nabu Casa o VPN).
- Sul telefono: iPhone -> app Home Assistant -> Impostazioni -> Notifiche -> attivare "Avvisi critici"; Android -> impostazioni notifiche dell'app -> canale "Alarm Stream" -> suono forte, importanza alta, e permesso "Non disturbare".

## 6. STATO ATTUALE E COSE DA FARE (in ordine)
1. **IP statico** 192.168.1.13 per Home Assistant (Impostazioni → Sistema → Rete). Verificare.
2. Incollare i **tre file completi** di `docs/homeassistant/` (configuration.yaml, scripts.yaml, automations.yaml) con File editor, sostituire `NOME_TELEFONO`, riavviare Home Assistant, verificare che compaia l'entità **Antifurto** (pannello allarme).
3. Installare l'**app Home Assistant** sul telefono (in casa, server 192.168.1.13:8123), trovare il nome `notify.mobile_app_...`.
4. **Comando**: i due fili della zona chiave nelle viti **centrale** e **in basso** del gruppo **Relay 1** del Marss; nel Marss, Output Configuration, uscita 1 **temporizzazione 2 s**; prova dall'app "Inserisci fuori casa"/"Disinserisci" (casa chiusa). Se la centrale fa il contrario, spostare il filo sulla vite in alto del gruppo.
5. **Allarme in corso**: comprare un **modulo relè 12 V 1 canale** (optoisolato). Bobina: `DC+` → vite **NO** del relè di allarme della KYO (accanto al filo rosso), `DC−` → un morsetto **−** della KYO, `IN` ponticellato a `DC+` (trigger "high"). Contatto: `COM` → **GND** del Marss, `NO` → **IN2** del Marss. Prova d'allarme: in2 rosso mentre suona; in HA "Antifurto allarme in corso" Acceso, pannello in stato "Allarme", notifica sul telefono.
6. **Accesso da fuori casa**: Home Assistant Cloud (Nabu Casa, prova gratuita un mese, poi ~7 €/mese) da Impostazioni → Home Assistant Cloud. Alternative: Tailscale/WireGuard (più passaggi). Niente porte aperte sul router.
7. **Backup**: Impostazioni → Sistema → Backup → Crea backup → scaricare sul PC.
8. Facoltativo: unire il branch `claude/new-session-33hkm7` su `main` (pull request) e cambiare l'URL dell'archivio in HA in `https://github.com/rudycen67/Prova` (attenzione: cambiare URL fa vedere l'add-on come nuovo: reinstallare).
9. Facoltativo: ventolina 12 V (30 mm) per il dissipatore della KYO: rosso su **+B** (22), nero su un **−**; se si fora la scatola per espellere l'aria, mettere una retina e fare il foro a centrale spenta.

## 7. RISOLUZIONE PROBLEMI RAPIDA
- **Pagina Marss non si apre / sensori HA "non disponibili"**: 1) `ping 192.168.1.249` da PuTTY; 2) riavviare l'add-on Bentel Socat Bridge; 3) togliere/ridare alimentazione al Marss 30 s; 4) controllare che l'IP di HA non sia cambiato (usare sempre il nome `92d7005e-bentel-socat` nella configurazione).
- **Add-on, Registro**: "SSL proto version used: SSLv3 … connection using RC4-MD5 … successfully connected" = tutto OK; "Operation timed out" = Marss intasato (riavviare Marss); "maxchildren are active, waiting" = normale, è la coda.
- **Home Assistant non raggiungibile**: cercare "homeassistant" nel programma "Dispositivi LAN" sul PC, provare `http://homeassistant.local:8123`; mai staccare la spina del Raspberry se non come ultima risorsa.
- **Errore di configurazione al riavvio**: aprire File editor, controllare il pallino verde/rosso in alto a destra del file, cercare righe duplicate (`script:` esiste già come `!include`).
- **Fusibile KYO**: 5 A, vetro; salta solo per corto +12 V ↔ negativo. Non sostituire con valori maggiori.

## 8. FILE DEL REPOSITORY DA CONOSCERE
- `repository.yaml` – archivio add-on.
- `bentel_socat/` – add-on (Dockerfile, run.sh, nginx-bridge.conf, config.yaml, DOCS.md, CHANGELOG.md, translations/).
- `docs/home-assistant-bentel-socat.md` – guida passo-passo e cronologia della diagnosi.
- `docs/home-assistant-marss.yaml` – esempio HA con commenti.
- `docs/homeassistant/configuration.yaml`, `scripts.yaml`, `automations.yaml` – file completi da incollare.
- `docs/HANDOFF.md` – questo documento.
