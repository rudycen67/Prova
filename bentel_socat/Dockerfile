# Immagine base ufficiale multi-architettura di Home Assistant (Alpine 3.24).
# Dal Supervisor 2026.04 l'argomento BUILD_FROM non viene piu' passato
# automaticamente, quindi la base va indicata in modo esplicito.
ARG BUILD_FROM=ghcr.io/home-assistant/base:3.24
FROM ${BUILD_FROM}

# ------------------------------------------------------------------------------
# Il modulo Marss IP Controller parla SOLO SSLv3 (con cifrari RC4): nessun
# OpenSSL di sistema lo supporta piu'. Compiliamo quindi un OpenSSL 1.1.1 con
# SSLv3 e cifrari deboli riabilitati, e un socat collegato staticamente a esso.
# Il socat di Alpine resta disponibile per la modalita' TCP semplice.
# ------------------------------------------------------------------------------
ARG OPENSSL_VERSION=1.1.1w
ARG OPENSSL_SHA256=cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8
ARG SOCAT_VERSION=1.8.0.3
ARG SOCAT_SHA256=a9f9eb6cfb9aa6b1b4b8fe260edbac3f2c743f294db1e362b932eb3feca37ba4

RUN apk add --no-cache socat \
 && apk add --no-cache --virtual .build-deps build-base perl linux-headers curl \
 && mkdir -p /tmp/build && cd /tmp/build \
 && curl -fsSL -o openssl.tar.gz "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" \
 && echo "${OPENSSL_SHA256}  openssl.tar.gz" | sha256sum -c - \
 && tar xzf openssl.tar.gz \
 && cd "openssl-${OPENSSL_VERSION}" \
 && ./config --prefix=/opt/ssl3 --openssldir=/opt/ssl3 \
        no-shared no-tests no-asm \
        enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers \
 && make -j"$(nproc)" build_libs \
 && make install_dev \
 && cd /tmp/build \
 && curl -fsSL -o socat.tar.gz "http://www.dest-unreach.org/socat/download/socat-${SOCAT_VERSION}.tar.gz" \
 && echo "${SOCAT_SHA256}  socat.tar.gz" | sha256sum -c - \
 && tar xzf socat.tar.gz \
 && cd "socat-${SOCAT_VERSION}" \
 && LIBS="-ldl -lpthread" ./configure \
        --disable-readline --disable-libwrap \
        --enable-openssl-base=/opt/ssl3 \
 && make -j"$(nproc)" socat \
 && install -m 0755 socat /usr/local/bin/socat-ssl3 \
 && /usr/local/bin/socat-ssl3 -V | grep -i "openssl" \
 && cd / && rm -rf /tmp/build /opt/ssl3 \
 && apk del .build-deps

# nginx fa da "sala d'attesa": i browser aprono molte connessioni insieme,
# il modulo Marss ne regge una sola. nginx le accoda e apre verso socat una
# connessione breve per richiesta.
RUN apk add --no-cache nginx

COPY run.sh /
COPY nginx-bridge.conf /etc/nginx/bridge.conf.template
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
