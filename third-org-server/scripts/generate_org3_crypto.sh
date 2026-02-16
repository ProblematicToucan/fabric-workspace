#!/usr/bin/env bash
#
# =============================================================================
# generate_org3_crypto.sh — Create Org3 identities with cryptogen (learning)
# =============================================================================
#
# LEARNING: cryptogen generates x509 certs and keys for Fabric identities. For a
# peer org it creates:
#   - CA and TLS CA (for signing certs and TLS)
#   - Peers (per Template count): identity + TLS under peers/<peer>.<domain>/
#   - Users (per Users count): Admin and User1 under users/
#   - MSP dir at org level: cacerts, tlscacerts, config (admincerts, etc.)
#
# Output layout (under organizations/peerOrganizations/org3.example.com/):
#   msp/           — org-level MSP (cacerts, tlscacerts, config.yaml)
#   peers/peer0.org3.example.com/ — peer identity + TLS (msp + tls/)
#   users/Admin@org3.example.com/  — admin user (msp + tls/)
#   users/User1@org3.example.com/ — standard user (msp + tls/)
#   tlsca/         — TLS CA cert (for client connections)
#
# Requires: cryptogen on PATH (e.g. fabric-samples/bin). Run from third-org-server.
# =============================================================================
set -e
ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)
. "${ROOTDIR}/../scripts/utils.sh"

export PATH="${ROOTDIR}/../../fabric-samples/bin:${PATH}"
if ! which cryptogen > /dev/null 2>&1; then
  fatalln "cryptogen not found. Add fabric-samples/bin to PATH."
fi

mkdir -p "${ROOTDIR}/organizations"
if [ -d "${ROOTDIR}/organizations/peerOrganizations" ]; then
  infoln "Removing existing Org3 crypto..."
  rm -Rf "${ROOTDIR}/organizations/peerOrganizations"
fi

infoln "Generating Org3 identities..."
set -x
cryptogen generate \
  --config="${ROOTDIR}/organizations/cryptogen/crypto-config-org3.yaml" \
  --output="${ROOTDIR}/organizations"
res=$?
{ set +x; } 2>/dev/null
[ $res -ne 0 ] && fatalln "Failed to generate Org3 certificates"
successln "Org3 crypto generated under third-org-server/organizations/"
