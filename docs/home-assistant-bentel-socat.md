# Centrale Bentel Kyo in Home Assistant: proxy socat senza terminale

Questa guida risolve il blocco descritto nel *Rapporto Tecnico Diagnostico*:
i file dell'add-on `bentel_socat` erano stati creati con il File Editor in
`/config/bentel_socat/`, ma il Supervisor cerca gli add-on locali **solo** in
`/addons/`, cartella che il File Editor non puo' raggiungere. Risultato:
`Timeout on /store/reload request` a ogni ricarica dello store.

La soluzione adottata e' il **Percorso A** del rapporto: l'add-on vive in questo
repository GitHub (pubblico) e Home Assistant lo scarica e lo costruisce da solo.
**Non serve nessun comando da terminale.**

Tutto cio' che segue si fa dal browser, nell'interfaccia di Home Assistant.

---

## 0. Prima di iniziare: pulizia della cartella sbagliata

Finche' la cartella `/config/bentel_socat/` esiste non da' fastidio al Supervisor
(lui non la legge), ma e' inutile e confonde. Rimuovila cosi':

1. Apri **File Editor** (add-on gia' installato).
2. Premi l'icona della cartella in alto a sinistra, entra in `bentel_socat`.
3. Per ogni file (`config.json`, `Dockerfile`, `run.sh`) apri il menu ⋮ e
   scegli **Elimina**; infine elimina la cartella stessa.

> Se lo store dava ancora timeout, dopo la pulizia esegui una volta
> **Impostazioni → Sistema → Hardware → ⋮ → Riavvia host** oppure, piu' veloce,
> **Impostazioni → Sistema → ⋮ (in alto a destra) → Riavvia Home Assistant →
> Riavvio avanzato → Riavvia Supervisor**.

---

## 1. Aggiungere questo repository allo store degli add-on

1. **Impostazioni → Componenti aggiuntivi** (su versioni recenti: *Apps*).
2. In basso a destra premi **Archivio dei componenti aggiuntivi** (*Install app*).
3. In alto a destra apri il menu **⋮ → Archivi** (*Repositories*).
4. Incolla esattamente:

   ```text
   https://github.com/rudycen67/Prova
   ```

5. Premi **Aggiungi**, poi **Chiudi**.
6. Se la nuova sezione **"Add-on di rudycen67"** non compare subito:
   **⋮ → Verifica aggiornamenti** e ricarica la pagina del browser.

> Il Supervisor legge il branch predefinito del repository (`main`). I file
> dell'add-on devono quindi essere gia' stati uniti su `main`.

---

## 2. Installare e configurare "Bentel Socat Bridge"

1. Nello store, nella sezione **Add-on di rudycen67**, apri **Bentel Socat
   Bridge** e premi **Installa**.
   Su Raspberry Pi 3 l'immagine viene costruita sul dispositivo: attendi
   **2-5 minuti** senza chiudere la pagina. Il progresso si vede in
   **Impostazioni → Sistema → Registri → Supervisor**.
2. Scheda **Configurazione**:
   - **Indirizzo IP della centrale Bentel**: `192.168.1.249`
   - **Porta della centrale Bentel**: `26501`
   - **Log dettagliato**: attivo (utile all'inizio, poi puoi spegnerlo)

   Nella sezione **Rete** piu' in basso c'e' la porta su cui Home Assistant
   espone il proxy (predefinita `26501`). Lasciala cosi' a meno che sia gia'
   occupata da altro. Premi **Salva**.
3. Scheda **Informazioni**: attiva **Avvia all'avvio** e **Watchdog**, poi
   premi **Avvia**.
4. Scheda **Registro**: devi leggere

   ```text
   INFO: Avvio del proxy socat verso la centrale Bentel Kyo...
   INFO: In ascolto su 0.0.0.0:26501 -> 192.168.1.249:26501
   ```

---

## 3. Collegare l'integrazione al proxy

Nell'integrazione Bentel/Kyo di Home Assistant usa come indirizzo
**l'IP di Home Assistant** (quello del Raspberry, es. `192.168.1.xxx`) e come
porta **26501**. Il proxy inoltra tutto alla centrale in modo trasparente.

---

## Se qualcosa non va

| Sintomo | Causa probabile | Cosa fare |
| --- | --- | --- |
| Il repository non si aggiunge ("Repository non valido") | URL scritto male o file non ancora su `main` | Ricontrolla l'URL; verifica su GitHub che `repository.yaml` sia visibile nella pagina principale del repo |
| L'add-on non compare nello store | Cache dello store | **⋮ → Verifica aggiornamenti**, poi ricarica il browser (Ctrl+F5) |
| "Installa" fallisce | Errore di build (rete assente, spazio esaurito) | Leggi **Impostazioni → Sistema → Registri → Supervisor**; riprova dopo aver liberato spazio |
| Nel log: `Connection refused` / `No route to host` | La centrale non risponde a quell'IP/porta | Verifica l'IP della centrale dal router; correggi in **Configurazione** e riavvia l'add-on |
| L'add-on si ferma subito | Opzione IP vuota o non valida | Leggi la scheda **Registro**, correggi la configurazione |

---

## Alternativa (Percorso B): Samba Share

Se preferisci tenere i file **in locale** sul Raspberry invece che su GitHub:

1. Installa l'add-on ufficiale **Samba share**, imposta nome utente e password,
   avvialo.
2. Da Windows apri `\\homeassistant` (o `\\<IP di Home Assistant>`), da Mac
   **Vai → Connetti al server → smb://homeassistant**.
3. Entra nella condivisione **addons** (e' la vera cartella `/addons/`).
4. Copia dentro, con trascinamento, l'intera cartella `bentel_socat` di questo
   repository (con `config.yaml`, `Dockerfile`, `run.sh`, `translations/`...).
5. Nello store: **⋮ → Verifica aggiornamenti**. L'add-on compare nella sezione
   **Componenti aggiuntivi locali**.

Attenzione: usa i file di questo repository, **non** quelli del rapporto. Il
`Dockerfile` originale (`FROM $BUILD_FROM`) non funziona piu' con il Supervisor
attuale, che dal 2026.04 non passa piu' quell'argomento; qui la base e' indicata
in modo esplicito.

---

## Cosa c'e' nel repository

```text
repository.yaml                 identifica questo repo come "archivio di add-on"
bentel_socat/
  config.yaml                   nome, versione, porte, opzioni configurabili
  Dockerfile                    immagine base HA + installazione di socat
  run.sh                        legge le opzioni e lancia socat
  translations/it.yaml, en.yaml etichette delle opzioni nella GUI
  DOCS.md                       documentazione mostrata nella scheda "Documentazione"
  icon.png, logo.png            icona nello store
```
