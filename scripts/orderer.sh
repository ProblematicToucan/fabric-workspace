#!/usr/bin/env bash
# Join orderer to channel via Channel Participation API (osnadmin)

channel_name=$1
WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}

export ORDERER_CA=${WORKSPACE_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${WORKSPACE_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${WORKSPACE_HOME}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

osnadmin channel join \
  --channelID "${channel_name}" \
  --config-block "${WORKSPACE_HOME}/channel-artifacts/${channel_name}.block" \
  -o localhost:7053 \
  --ca-file "$ORDERER_CA" \
  --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
  --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" \
  >> "${WORKSPACE_HOME}/log.txt" 2>&1
