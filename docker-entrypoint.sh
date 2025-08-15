#!/bin/bash
set -e

CHILLI_USER=chilli
CHILLI_GROUP=chilli

echo "[INFO] Inicializando CoovaChilli..."
echo "[INFO] WAN: ${HS_WANIF} | LAN: ${HS_LANIF}"

if [ -f /my-chilli.conf ]; then
    echo "[INFO] Usando configuração personalizada."
    cp /my-chilli.conf /etc/chilli/chilli.conf
fi

chown -R ${CHILLI_USER}:${CHILLI_GROUP} /etc/chilli

echo "[INFO] Configurando interfaces de rede..."
ip link set "${HS_WANIF}" up || true
ip link set "${HS_LANIF}" up || true

echo "[INFO] Dropando privilégios para usuário não-root..."
exec su-exec ${CHILLI_USER}:${CHILLI_GROUP} "$@"
