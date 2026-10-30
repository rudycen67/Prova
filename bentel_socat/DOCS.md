# Bentel Socat Bridge

## Cosa fa

Fa da ponte tra Home Assistant (o il tuo browser) e il **modulo IP
dell'antifurto**. Nel caso tipico il modulo e' un **Marss IP Controller**
(IPC-3008/3108, 3004/3104, 3002/3102) collegato alla centrale Bentel: ha un web
server integrato sulla porta 26501 che parla solo **SSLv3**, un protocollo che
nessun browser moderno accetta piu'. L'add-on apre lui la connessione SSLv3 e
ti mostra la pagina del modulo in HTTP semplice:

```text
http://<IP di Home Assistant>:26501/
```

Utente e password sono quelli del modulo (di fabbrica: `admin` / `marss`).

## Installazione

1. **Impostazioni → Applicazioni → Installa applicazione** (in alto a destra ⋮
   → *Archivi*), incolla `https://github.com/rudycen67/Prova` e premi
   **Aggiungi**.
2. Apri **Bentel Socat Bridge** e premi **Installa**. L'add-on compila OpenSSL
   sul dispositivo: su Raspberry Pi 3 servono **15-30 minuti**. Non chiudere la
   pagina.
3. Scheda **Configurazione**: IP del modulo, porta `443`, modalita' `ssl3`. **Salva**.
4. Scheda **Informazioni**: *Avvia all'avvio* e **Avvia**.
5. Scheda **Registro**: deve comparire `In ascolto su 0.0.0.0:26501 -> ...`.
6. Dal browser apri `http://<IP di Home Assistant>:26501/`.

## Come funziona (modalita' cifrate)

```text
browser / Home Assistant --HTTP--> nginx :26501 --> socat-ssl3 :26502 --SSLv3--> modulo :443
```

nginx accoda le richieste e apre verso socat una connessione breve per
richiesta; socat ne tiene aperta **una sola alla volta** verso il modulo, che
non ne regge di piu'.

## Opzioni

| Opzione | Predefinito | Significato |
| --- | --- | --- |
| `bentel_host` | `192.168.1.249` | IP del modulo (o della centrale) |
| `bentel_port` | `443` | Porta TCP del modulo: 443 = pagina web; 26501 = protocollo dell'app (non HTTP) |
| `tls_mode` | `ssl3` | `ssl3` Marss IP Controller; `tls1` TLS 1.0; `tls_auto` negozia; `none` inoltro TCP puro |
| `verbose` | `true` | Scrive nel log ogni connessione aperta/chiusa |

La porta su cui Home Assistant espone il ponte (predefinita `26501`) si cambia
nella sezione **Rete** della scheda Configurazione.

## Risoluzione dei problemi

- **Nel log compare `SSL_connect` / `handshake failure`**: il modulo non accetta
  la modalita' scelta. Prova `tls_auto`, poi `tls1`.
- **`Connection refused` / `No route to host`**: il modulo non risponde
  all'IP/porta indicati. Verifica l'IP dal router.
- **L'installazione fallisce**: leggi **Impostazioni → Sistema → Registri →
  Supervisor**. Di solito e' spazio disco esaurito o rete assente durante la
  compilazione; riprova.
- **La pagina si apre ma manca grafica o pulsanti**: il modulo potrebbe usare
  link assoluti `https://...`; segnalalo con uno screenshot per adattare il ponte.
