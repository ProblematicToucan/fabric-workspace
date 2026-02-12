#!/usr/bin/env bash
# Join the peer to the channel. Runs peer CLI on the host (like test-network); no container access.
# Run from fabric-workspace root. Peer must be up; channel block must exist in channel-artifacts/.

set -e
CHANNEL_NAME="${1:-mychannel}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BLOCK="${ROOT}/channel-artifacts/${CHANNEL_NAME}.block"

test -f "$BLOCK" || { echo "Channel block not found: $BLOCK. Run scripts/create_channel.sh first."; exit 1; }

# Same pattern as test-network: admin identity + peer address (peer CLI talks to peer from host)
export CORE_PEER_LOCALMSPID=GarammMSP
export CORE_PEER_MSPCONFIGPATH="${ROOT}/organizations/peerOrganizations/garamm.dev/users/Admin@garamm.dev/msp"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE="${ROOT}/organizations/peerOrganizations/garamm.dev/peers/peer0.garamm.dev/tls/ca.crt"
export CORE_PEER_TLS_ENABLED=true

echo "Joining peer (localhost:7051) to channel: ${CHANNEL_NAME}"
peer channel join -b "${BLOCK}"

echo "Peer joined channel ${CHANNEL_NAME}."
