#!/usr/bin/env bash
#
# =============================================================================
# orderer.sh — Join orderer to a channel (Channel Participation API)
# =============================================================================
#
# Uses osnadmin channel join to add the orderer to the channel. The channel
# genesis block must already exist under channel-artifacts/<channel_name>.block.
# Orderer admin listens on 7053; TLS certs from cryptogen output.
#
# Usage: . scripts/orderer.sh <channel_name>
#        (sourced so caller can read $? after osnadmin)
# =============================================================================

channel_name=$1
WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}

# Orderer TLS and admin client certs (from cryptogen)
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
