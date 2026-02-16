#!/usr/bin/env bash
#
# =============================================================================
# generate_crypto.sh — Generate crypto material with cryptogen
# =============================================================================
#
# Creates MSP material for:
#   - Orderer org (example.com) — one orderer node
#   - Peer org Org1 (org1.example.com) — one peer, one user
#
# Output directories (under organizations/):
#   - ordererOrganizations/example.com/
#   - peerOrganizations/org1.example.com/
#
# Config files: organizations/cryptogen/crypto-config-orderer.yaml
#               organizations/cryptogen/crypto-config-org1.yaml
#
# Usage: scripts/generate_crypto.sh  (or via network.sh createOrgs)
# Prereq: cryptogen on PATH (e.g. fabric-samples/bin)
# =============================================================================

WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}
. ${WORKSPACE_HOME}/scripts/utils.sh

if ! which cryptogen > /dev/null 2>&1; then
  fatalln "cryptogen not found. Add fabric-samples/bin to PATH."
fi

# Remove existing crypto so we get a clean regenerate
if [ -d "${WORKSPACE_HOME}/organizations/peerOrganizations" ]; then
  infoln "Removing existing crypto..."
  rm -Rf "${WORKSPACE_HOME}/organizations/peerOrganizations" "${WORKSPACE_HOME}/organizations/ordererOrganizations"
fi

# Peer org first (orderer org second is typical in samples)
infoln "Creating Org1 identities (peer)"
set -x
cryptogen generate --config="${WORKSPACE_HOME}/organizations/cryptogen/crypto-config-org1.yaml" --output="${WORKSPACE_HOME}/organizations"
res=$?
{ set +x; } 2>/dev/null
[ $res -ne 0 ] && fatalln "Failed to generate Org1 certificates"

infoln "Creating Orderer org identities"
set -x
cryptogen generate --config="${WORKSPACE_HOME}/organizations/cryptogen/crypto-config-orderer.yaml" --output="${WORKSPACE_HOME}/organizations"
res=$?
{ set +x; } 2>/dev/null
[ $res -ne 0 ] && fatalln "Failed to generate Orderer certificates"

successln "Crypto material generated under organizations/"
