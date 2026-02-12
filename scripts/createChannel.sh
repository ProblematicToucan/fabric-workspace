#!/usr/bin/env bash
# Create channel: 1) genesis block, 2) orderer joins channel, 3) peer joins channel
# Single org — no anchor peer update (optional for one peer).

. scripts/envVar.sh

CHANNEL_NAME="${1:-mychannel}"
DELAY="${2:-3}"
MAX_RETRY="${3:-5}"
WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}

: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

mkdir -p channel-artifacts

createChannelGenesisBlock() {
  setGlobals
  which configtxgen > /dev/null 2>&1 || fatalln "configtxgen not found. Add fabric-samples/bin to PATH."
  set -x
  FABRIC_CFG_PATH=${WORKSPACE_HOME}/configtx configtxgen \
    -profile ChannelUsingRaft \
    -outputBlock "${WORKSPACE_HOME}/channel-artifacts/${CHANNEL_NAME}.block" \
    -channelID "$CHANNEL_NAME"
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel genesis block"
}

ordererJoinChannel() {
  local rc=1
  local COUNTER=1
  infoln "Joining orderer to channel ${CHANNEL_NAME}..."
  while [ $rc -ne 0 ] && [ $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    . scripts/orderer.sh "$CHANNEL_NAME"
    rc=$?
    COUNTER=$((COUNTER + 1))
  done
  [ -f log.txt ] && cat log.txt
  verifyResult $rc "Orderer failed to join channel after $MAX_RETRY attempts"
}

joinPeerToChannel() {
  setGlobals
  export FABRIC_CFG_PATH="${WORKSPACE_HOME}/peercfg"
  local rc=1
  local COUNTER=1
  BLOCKFILE="${WORKSPACE_HOME}/channel-artifacts/${CHANNEL_NAME}.block"
  infoln "Joining peer to channel ${CHANNEL_NAME}..."
  while [ $rc -ne 0 ] && [ $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    set -x
    peer channel join -b "$BLOCKFILE" >> "${WORKSPACE_HOME}/log.txt" 2>&1
    res=$?
    { set +x; } 2>/dev/null
    rc=$res
    COUNTER=$((COUNTER + 1))
  done
  [ -f log.txt ] && cat log.txt
  verifyResult $rc "Peer failed to join channel ${CHANNEL_NAME} after $MAX_RETRY attempts"
}

# Step 1: generate channel genesis block
infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${WORKSPACE_HOME}/configtx createChannelGenesisBlock

# Step 2: orderer joins channel (channel participation API)
ordererJoinChannel
successln "Channel '${CHANNEL_NAME}' created on orderer"

# Step 3: peer joins channel
joinPeerToChannel
successln "Peer joined channel '${CHANNEL_NAME}'"
