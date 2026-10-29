#!/command/with-contenv bashio
# ==============================================================================
# Bentel Socat Bridge
# Proxy TCP trasparente: porta 26501 del container -> centrale Bentel Kyo.
# Le opzioni si impostano dalla scheda "Configurazione" dell'add-on.
# ==============================================================================
set -e

BENTEL_HOST=$(bashio::config 'bentel_host')
BENTEL_PORT=$(bashio::config 'bentel_port')
LISTEN_PORT=26501

SOCAT_OPTS=()
if bashio::config.true 'verbose'; then
    SOCAT_OPTS+=(-d -d)
fi

bashio::log.info "Avvio del proxy socat verso la centrale Bentel Kyo..."
bashio::log.info "In ascolto su 0.0.0.0:${LISTEN_PORT} -> ${BENTEL_HOST}:${BENTEL_PORT}"

exec socat "${SOCAT_OPTS[@]}" \
    "TCP-LISTEN:${LISTEN_PORT},fork,reuseaddr" \
    "TCP:${BENTEL_HOST}:${BENTEL_PORT}"
