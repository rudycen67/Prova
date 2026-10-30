#!/command/with-contenv bashio
# ==============================================================================
# Bentel Socat Bridge
#
# Modalita' (opzione tls_mode):
#   ssl3     : il modulo (Marss IP Controller) parla SSLv3. socat apre la
#              connessione cifrata; nginx davanti accoda le richieste dei
#              browser e offre HTTP semplice sulla porta 26501.
#   tls1     : come sopra ma con TLS 1.0.
#   tls_auto : lascia negoziare a OpenSSL da SSLv3 in su.
#   none     : inoltro TCP trasparente, nessuna cifratura (versione 1.x).
# ==============================================================================
set -e

BENTEL_HOST=$(bashio::config 'bentel_host')
BENTEL_PORT=$(bashio::config 'bentel_port')
TLS_MODE=$(bashio::config 'tls_mode')
LISTEN_PORT=26501
INNER_PORT=26502

SOCAT_OPTS=()
if bashio::config.true 'verbose'; then
    SOCAT_OPTS+=(-d -d)
fi

# @SECLEVEL=0: necessario per RC4/MD5 e chiavi RSA corte dei moduli vecchi.
CIPHERS="ALL:@SECLEVEL=0"
SSL_COMMON="openssl-verify=0,openssl-no-sni,openssl-cipherlist=${CIPHERS},connect-timeout=20"

case "${TLS_MODE}" in
    none)
        TARGET="TCP:${BENTEL_HOST}:${BENTEL_PORT},connect-timeout=20"
        ;;
    tls1)
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=TLS1,openssl-max-proto-version=TLS1"
        ;;
    tls_auto)
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=SSL3"
        ;;
    ssl3|*)
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=SSL3,openssl-max-proto-version=SSL3"
        ;;
esac

bashio::log.info "Avvio del ponte verso il modulo IP dell'antifurto..."
bashio::log.info "Modalita': ${TLS_MODE}"

if [ "${TLS_MODE}" = "none" ]; then
    bashio::log.info "In ascolto su 0.0.0.0:${LISTEN_PORT} -> ${BENTEL_HOST}:${BENTEL_PORT} (TCP trasparente)"
    exec socat "${SOCAT_OPTS[@]}" \
        "TCP-LISTEN:${LISTEN_PORT},fork,reuseaddr" \
        "${TARGET}"
fi

# --- modalita' cifrate: socat interno (una connessione alla volta) + nginx ---
mkdir -p /tmp/nginx_client /tmp/nginx_proxy /tmp/nginx_fastcgi /tmp/nginx_uwsgi /tmp/nginx_scgi
sed -e "s/__HOST__/${BENTEL_HOST}/g" -e "s/__PORT__/${BENTEL_PORT}/g" \
    /etc/nginx/bridge.conf.template > /etc/nginx/bridge.conf

bashio::log.info "socat: 127.0.0.1:${INNER_PORT} -> ${BENTEL_HOST}:${BENTEL_PORT} (max 1 connessione alla volta)"
/usr/local/bin/socat-ssl3 "${SOCAT_OPTS[@]}" \
    "TCP-LISTEN:${INNER_PORT},bind=127.0.0.1,fork,reuseaddr,max-children=1,backlog=64" \
    "${TARGET}" &
SOCAT_PID=$!

bashio::log.info "nginx: in ascolto su 0.0.0.0:${LISTEN_PORT} (accoda le richieste dei browser)"
bashio::log.info "Apri dal browser: http://<IP di Home Assistant>:${LISTEN_PORT}/"
nginx -c /etc/nginx/bridge.conf &
NGINX_PID=$!

# Se uno dei due termina, esce anche l'add-on (cosi' il watchdog lo riavvia).
trap 'kill ${SOCAT_PID} ${NGINX_PID} 2>/dev/null; exit 0' TERM INT
wait -n ${SOCAT_PID} ${NGINX_PID}
bashio::log.error "Un componente del ponte si e' fermato: esco."
kill ${SOCAT_PID} ${NGINX_PID} 2>/dev/null || true
exit 1
