#!/usr/bin/env bash
#
# =============================================================================
# third-org-server — Add a new peer org (Org3) to an existing channel
# =============================================================================
#
# LEARNING: This playground shows how to add a new organization when the
# network already has an orderer and peer with a channel. Nothing here modifies
# the parent fabric-workspace/ network.sh or config; all state lives under
# third-org-server/.
#
# Order of operations:
#   1. generate  — Create Org3 identities (crypto) under this directory.
#   2. add-org   — Update channel config to include Org3 (needs parent up + channel).
#   3. up        — Start the Org3 peer container on the same Docker network.
#   4. join      — Join that peer to the channel (needs block 0 + peer up).
#   5. down      — Stop Org3 peer and remove generated crypto/artifacts (parent unchanged).
#
# Usage:
#   ./run.sh generate           Generate Org3 crypto only
#   ./run.sh add-org [channel]  Add Org3 to channel (default: mychannel)
#   ./run.sh up                 Start peer0.org3 (port 8051, network fabric_workspace)
#   ./run.sh join [channel]     Join peer0.org3 to channel
#   ./run.sh down               Stop peer0.org3 and remove generated artifacts
#
# =============================================================================
set -e
ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH="${ROOTDIR}/../fabric-samples/bin:${PATH}"

# Support both "docker compose" and "docker-compose" (and podman)
: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi

MODE="${1:-}"
CHANNEL_NAME="${2:-mychannel}"

case "$MODE" in
  generate)
    # Creates organizations/peerOrganizations/org3.example.com/ (peers, users, MSP).
    "${ROOTDIR}/scripts/generate_org3_crypto.sh"
    ;;
  add-org)
    # Fetches channel config (as Org1), adds Org3 MSP, signs and submits update.
    "${ROOTDIR}/scripts/add_org3_to_channel.sh" "$CHANNEL_NAME"
    ;;
  up)
    if [ ! -d "${ROOTDIR}/organizations/peerOrganizations/org3.example.com" ]; then
      echo "Run ./run.sh generate first"
      exit 1
    fi
    $CONTAINER_CLI_COMPOSE -f "${ROOTDIR}/docker-compose.yaml" up -d
    $CONTAINER_CLI ps -a | grep -E 'peer0|orderer' || true
    echo "Peer Org3 listening on localhost:8051"
    ;;
  join)
    # Fetches genesis block if needed, then peer channel join as Org3.
    "${ROOTDIR}/scripts/join_peer_org3.sh" "$CHANNEL_NAME"
    ;;
  down)
    $CONTAINER_CLI_COMPOSE -f "${ROOTDIR}/docker-compose.yaml" down --volumes 2>/dev/null || true
    $CONTAINER_CLI rm -f peer0.org3.example.com 2>/dev/null || true
    echo "Removing generated artifacts (crypto, channel-artifacts, log)..."
    rm -rf "${ROOTDIR}/organizations/peerOrganizations"
    rm -rf "${ROOTDIR}/channel-artifacts"
    rm -f "${ROOTDIR}/log.txt"
    echo "Org3 peer stopped; generated artifacts removed"
    ;;
  *)
    echo "Usage: $0 generate | add-org [channel] | up | join [channel] | down"
    exit 1
    ;;
esac
