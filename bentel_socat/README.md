# Bentel Socat Bridge

Add-on per Home Assistant che avvia un **proxy TCP trasparente** (`socat`)
verso la centrale di allarme **Bentel Kyo**.

Tutto quello che arriva sulla porta `26501` di Home Assistant viene inoltrato,
senza modifiche, alla centrale (per impostazione predefinita
`192.168.1.249:26501`). Indirizzo e porta si cambiano dalla scheda
**Configurazione** dell'add-on, senza terminale.

Guida completa, solo da interfaccia grafica:
[docs/home-assistant-bentel-socat.md](../docs/home-assistant-bentel-socat.md).
