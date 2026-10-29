# Immagine base ufficiale multi-architettura di Home Assistant (Alpine 3.24).
# Dal Supervisor 2026.04 l'argomento BUILD_FROM non viene piu' passato
# automaticamente, quindi la base va indicata in modo esplicito.
ARG BUILD_FROM=ghcr.io/home-assistant/base:3.24
FROM ${BUILD_FROM}

RUN apk add --no-cache socat

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
