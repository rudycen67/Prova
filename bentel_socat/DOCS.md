# Bentel Socat Bridge

## Cosa fa

Avvia `socat` in ascolto sulla porta `26501` e inoltra ogni connessione alla
centrale Bentel Kyo. L'integrazione in Home Assistant va quindi configurata
puntando a **l'indirizzo IP di Home Assistant, porta 26501** (o la porta che
hai scelto nella sezione *Rete*).

## Installazione

1. **Impostazioni → Componenti aggiuntivi → Archivio** (in alto a destra ⋮ →
   *Archivi*), incolla `https://github.com/rudycen67/Prova` e premi **Aggiungi**.
2. Cerca **Bentel Socat Bridge** nello store e premi **Installa**. Su un
   Raspberry Pi 3 la costruzione dell'immagine richiede qualche minuto.
3. Nella scheda **Configurazione** controlla l'IP e la porta della centrale,
   poi **Salva**.
4. Nella scheda **Informazioni** attiva *Avvia all'avvio* e premi **Avvia**.
5. Nella scheda **Registro** devi vedere
   `In ascolto su 0.0.0.0:26501 -> 192.168.1.249:26501`.

## Opzioni

| Opzione | Predefinito | Significato |
| --- | --- | --- |
| `bentel_host` | `192.168.1.249` | IP locale della centrale Bentel Kyo |
| `bentel_port` | `26501` | Porta TCP della centrale |
| `verbose` | `true` | Scrive nel log ogni connessione aperta/chiusa |

La porta su cui Home Assistant espone il proxy (predefinita `26501`) si cambia
nella sezione **Rete** della scheda Configurazione, non tra le opzioni.

## Risoluzione dei problemi

- **Il log mostra `Connection refused` o `No route to host`**: la centrale non
  risponde all'IP/porta indicati. Verifica l'IP dal router e che la centrale sia
  raggiungibile dalla stessa rete di Home Assistant.
- **L'add-on non compare nello store**: dal menu ⋮ dello store premi
  **Verifica aggiornamenti**, poi ricarica la pagina del browser.
- **L'add-on si ferma subito**: leggi la scheda Registro; se l'opzione
  `bentel_host` e' vuota o non valida `socat` termina con un errore esplicito.
