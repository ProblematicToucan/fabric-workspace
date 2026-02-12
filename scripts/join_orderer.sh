#!/usr/bin/env bash
# Join the orderer to the channel via osnadmin.
# Run from fabric-workspace root. Orderer must be up. Requires osnadmin in PATH.

set -e
CHANNEL_NAME="${1:-mychannel}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ORDERER_HOST="${ORDERER_HOST:-localhost}"
ORDERER_ADMIN_PORT="${ORDERER_ADMIN_PORT:-7053}"
ORDERER_TLS_DIR="${ROOT}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls"
BLOCK="${ROOT}/channel-artifacts/${CHANNEL_NAME}.block"

test -f "$BLOCK" || { echo "Channel block not found: $BLOCK. Run scripts/create_channel.sh first."; exit 1; }
test -f "${ORDERER_TLS_DIR}/server.crt" || { echo "Orderer TLS not found. Run scripts/generate_crypto.sh first."; exit 1; }

echo "Joining orderer to channel: ${CHANNEL_NAME} (${ORDERER_HOST}:${ORDERER_ADMIN_PORT})"
osnadmin channel join \
  --channelID "${CHANNEL_NAME}" \
  --config-block "${BLOCK}" \
  -o "${ORDERER_HOST}:${ORDERER_ADMIN_PORT}" \
  --ca-file "${ORDERER_TLS_DIR}/ca.crt" \
  --client-cert "${ORDERER_TLS_DIR}/server.crt" \
  --client-key "${ORDERER_TLS_DIR}/server.key"

echo "Orderer joined channel ${CHANNEL_NAME}."
