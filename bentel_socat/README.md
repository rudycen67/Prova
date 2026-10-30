# Bentel Socat Bridge

Add-on per Home Assistant che fa da ponte verso il **modulo IP dell'antifurto**
(Marss IP Controller collegato a una centrale Bentel). Il modulo parla solo
**SSLv3**, rifiutato da tutti i browser moderni: l'add-on compila un OpenSSL
con SSLv3 riabilitato e offre la pagina web del modulo in HTTP semplice su
`http://<IP di Home Assistant>:26501/`.

Modalita' `none` = semplice proxy TCP trasparente (versione 1.x).

Guida completa, solo da interfaccia grafica:
[docs/home-assistant-bentel-socat.md](../docs/home-assistant-bentel-socat.md).
