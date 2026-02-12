#!/usr/bin/env bash
# Generate the channel genesis block with configtxgen.
# Run from fabric-workspace root. Requires configtxgen in PATH.

set -e
CHANNEL_NAME="${1:-mychannel}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p channel-artifacts
export FABRIC_CFG_PATH="${ROOT}/configtx"

echo "Creating channel genesis block for channel: ${CHANNEL_NAME}"
configtxgen -profile MyChannel -outputBlock "${ROOT}/channel-artifacts/${CHANNEL_NAME}.block" -channelID "${CHANNEL_NAME}"

echo "Channel block written to: channel-artifacts/${CHANNEL_NAME}.block"
