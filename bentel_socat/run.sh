#!/command/with-contenv bashio
# ==============================================================================
# Bentel Socat Bridge
# Ponte TCP: porta 26501 del container -> modulo IP dell'antifurto.
#
# Modalita' (opzione tls_mode):
#   ssl3     : il modulo parla SSLv3 (Marss IP Controller). socat apre la
#              connessione cifrata e offre HTTP semplice sulla porta 26501.
#   tls1     : come sopra ma con TLS 1.0.
#   tls_auto : lascia negoziare a OpenSSL da SSLv3 in su.
#   none     : inoltro TCP trasparente, nessuna cifratura (versione 1.x).
# ==============================================================================
set -e

BENTEL_HOST=$(bashio::config 'bentel_host')
BENTEL_PORT=$(bashio::config 'bentel_port')
TLS_MODE=$(bashio::config 'tls_mode')
LISTEN_PORT=26501

SOCAT_OPTS=()
if bashio::config.true 'verbose'; then
    SOCAT_OPTS+=(-d -d)
fi

# @SECLEVEL=0: necessario per RC4/MD5 e chiavi RSA corte dei moduli vecchi.
CIPHERS="ALL:@SECLEVEL=0"
SSL_COMMON="openssl-verify=0,openssl-no-sni,openssl-cipherlist=${CIPHERS}"

case "${TLS_MODE}" in
    none)
        SOCAT_BIN="socat"
        TARGET="TCP:${BENTEL_HOST}:${BENTEL_PORT}"
        ;;
    tls1)
        SOCAT_BIN="/usr/local/bin/socat-ssl3"
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=TLS1,openssl-max-proto-version=TLS1"
        ;;
    tls_auto)
        SOCAT_BIN="/usr/local/bin/socat-ssl3"
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=SSL3"
        ;;
    ssl3|*)
        SOCAT_BIN="/usr/local/bin/socat-ssl3"
        TARGET="OPENSSL:${BENTEL_HOST}:${BENTEL_PORT},${SSL_COMMON},openssl-min-proto-version=SSL3,openssl-max-proto-version=SSL3"
        ;;
esac

bashio::log.info "Avvio del ponte socat verso il modulo IP dell'antifurto..."
bashio::log.info "Modalita': ${TLS_MODE}"
bashio::log.info "In ascolto su 0.0.0.0:${LISTEN_PORT} -> ${BENTEL_HOST}:${BENTEL_PORT}"
if [ "${TLS_MODE}" != "none" ]; then
    bashio::log.info "Apri dal browser: http://<IP di Home Assistant>:${LISTEN_PORT}/"
fi

exec "${SOCAT_BIN}" "${SOCAT_OPTS[@]}" \
    "TCP-LISTEN:${LISTEN_PORT},fork,reuseaddr" \
    "${TARGET}"
