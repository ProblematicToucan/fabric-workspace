#!/usr/bin/env bash
#
# =============================================================================
# join_peer_org3.sh — Join peer0.org3 to the channel (learning)
# =============================================================================
#
# LEARNING: To join a peer to a channel you need the channel's genesis block
# (block 0). The peer then replays blocks from the orderer to build its ledger.
#
# Why two identities?
#   - Fetching block 0: we use Org1 (parent) and the existing orderer, because
#     any channel member can fetch blocks. We write the block under third-org-server.
#   - Joining: we use Org3 identity and CORE_PEER_ADDRESS=localhost:8051 (our
#     peer). The join is sent to the Org3 peer; that peer uses the block to
#     join the channel.
#
# Run after: add_org3_to_channel.sh (Org3 must be on the channel) and run.sh up.
# =============================================================================
set -e
THIRD_ROOT=$(cd "$(dirname "$0")/.." && pwd)
PARENT_ROOT="${THIRD_ROOT}/.."
CHANNEL_NAME="${1:-mychannel}"
DELAY="${2:-3}"
MAX_RETRY="${3:-5}"

export PATH="${PARENT_ROOT}/../fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${PARENT_ROOT}/peercfg"
. "${PARENT_ROOT}/scripts/utils.sh"

# -----------------------------------------------------------------------------
# Org3 peer CLI env — tells the peer CLI which peer and which identity to use.
# Port 8051 is the host mapping for peer0.org3 (container listens on 7051).
# -----------------------------------------------------------------------------
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org3MSP
export CORE_PEER_TLS_ROOTCERT_FILE="${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
export CORE_PEER_ADDRESS=localhost:8051

BLOCKFILE="${THIRD_ROOT}/channel-artifacts/${CHANNEL_NAME}.block"

# -----------------------------------------------------------------------------
# Fetch channel genesis block (block 0) if we don't have it yet.
# Uses Org1 (parent) and orderer at 7050; result is the same for any member.
# -----------------------------------------------------------------------------
if [ ! -f "${BLOCKFILE}" ]; then
  infoln "Fetching channel genesis block..."
  export WORKSPACE_HOME="${PARENT_ROOT}"
  . "${PARENT_ROOT}/scripts/envVar.sh"
  setGlobals
  peer channel fetch 0 "${BLOCKFILE}" -o localhost:7050 -c "${CHANNEL_NAME}" --tls --cafile "$ORDERER_CA" >> "${THIRD_ROOT}/log.txt" 2>&1
  res=$?
  . "${PARENT_ROOT}/scripts/envVar.sh"
  verifyResult $res "Failed to fetch channel block"
  # Restore Org3 env so the join below targets our peer with Org3 identity.
  export CORE_PEER_LOCALMSPID=Org3MSP
  export CORE_PEER_TLS_ROOTCERT_FILE="${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"
  export CORE_PEER_MSPCONFIGPATH="${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
  export CORE_PEER_ADDRESS=localhost:8051
fi

# -----------------------------------------------------------------------------
# Join: send the genesis block to the Org3 peer. The peer joins the channel
# and will pull subsequent blocks from the orderer. Retry a few times in case
# the peer is still starting.
# -----------------------------------------------------------------------------
infoln "Joining peer0.org3 to channel ${CHANNEL_NAME}..."
rc=1
COUNTER=1
while [ $rc -ne 0 ] && [ $COUNTER -lt $MAX_RETRY ]; do
  sleep $DELAY
  peer channel join -b "${BLOCKFILE}" >> "${THIRD_ROOT}/log.txt" 2>&1
  rc=$?
  COUNTER=$((COUNTER + 1))
done
[ -f "${THIRD_ROOT}/log.txt" ] && tail -20 "${THIRD_ROOT}/log.txt"
[ $rc -ne 0 ] && fatalln "Peer failed to join channel after $MAX_RETRY attempts"
successln "peer0.org3 joined channel ${CHANNEL_NAME}"
