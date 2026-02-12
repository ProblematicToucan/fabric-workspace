#!/usr/bin/env bash
# Join the peer to the channel. Uses docker exec on peer0.garamm.dev.
# Run from fabric-workspace root. Peer must be up; channel block must exist in channel-artifacts/.

set -e
CHANNEL_NAME="${1:-mychannel}"
PEER_CONTAINER="${PEER_CONTAINER:-peer0.garamm.dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BLOCK="/etc/hyperledger/channel-artifacts/${CHANNEL_NAME}.block"

echo "Joining peer ${PEER_CONTAINER} to channel: ${CHANNEL_NAME}"
docker exec "${PEER_CONTAINER}" peer channel join -b "${BLOCK}"

echo "Peer joined channel ${CHANNEL_NAME}."
