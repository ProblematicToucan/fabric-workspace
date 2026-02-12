#!/usr/bin/env bash
#
# Minimal Fabric network: 1 orderer + 1 peer (Org1)
# For learning. Uses fabric-samples/bin for tools if available.
#
# Usage:
#   ./network.sh up              — generate crypto (if needed), start containers
#   ./network.sh up createChannel — up + create channel and join peer
#   ./network.sh createChannel    — create channel and join peer (network must be up)
#   ./network.sh down            — stop and remove containers/volumes/crypto
#

set -e
ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH="${ROOTDIR}/../fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${ROOTDIR}/configtx"
export WORKSPACE_HOME="${ROOTDIR}"
export VERBOSE="${VERBOSE:-false}"

pushd "${ROOTDIR}" > /dev/null
trap "popd > /dev/null" EXIT

. scripts/utils.sh

: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
  : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
: ${CHANNEL_NAME:="mychannel"}
: ${CLI_DELAY:="3"}
: ${MAX_RETRY:="5"}

function createOrgs() {
  if [ ! -d "organizations/peerOrganizations" ]; then
    scripts/generate_crypto.sh
  else
    infoln "Crypto already present, skipping generation"
  fi
}

function networkUp() {
  createOrgs
  infoln "Starting containers (orderer + peer)..."
  ${CONTAINER_CLI_COMPOSE} up -d
  ${CONTAINER_CLI} ps -a
  sleep 2
  infoln "Network is up. Orderer: 7050/7053, Peer: 7051"
}

function createChannel() {
  if ! ${CONTAINER_CLI} info > /dev/null 2>&1; then
    fatalln "Docker is not running"
  fi
  if ! ${CONTAINER_CLI} ps --format '{{.Names}}' | grep -q 'orderer.example.com'; then
    infoln "Network not up; bringing up first..."
    networkUp
  fi
  infoln "Creating channel '${CHANNEL_NAME}' and joining peer..."
  scripts/createChannel.sh "$CHANNEL_NAME" "$CLI_DELAY" "$MAX_RETRY"
}

function networkDown() {
  infoln "Stopping network..."
  ${CONTAINER_CLI_COMPOSE} down --volumes 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  if [ "$1" != "restart" ]; then
    infoln "Removing crypto and channel artifacts..."
    rm -rf organizations/peerOrganizations organizations/ordererOrganizations
    rm -rf channel-artifacts log.txt
    ${CONTAINER_CLI} volume rm fabric-workspace_orderer.example.com fabric-workspace_peer0.org1.example.com 2>/dev/null || true
  fi
  successln "Network down"
}

# Parse mode
MODE="${1:-}"
SUB="${2:-}"
shift 2>/dev/null || true

# Flags
while [[ $# -ge 1 ]]; do
  case "$1" in
    -c) CHANNEL_NAME="$2"; shift 2 ;;
    -d) CLI_DELAY="$2"; shift 2 ;;
    -r) MAX_RETRY="$2"; shift 2 ;;
    -verbose) VERBOSE=true; shift ;;
    -h)
      println "Usage: ./network.sh up | up createChannel | createChannel | down"
      println "  up              — start 1 orderer + 1 peer (generate crypto if needed)"
      println "  up createChannel — up then create channel and join peer"
      println "  createChannel   — create channel and join peer (network must be up)"
      println "  down            — stop and remove containers, crypto, artifacts"
      println "Options: -c <channel> -d <delay> -r <retries> -verbose"
      exit 0
      ;;
    *) shift ;;
  esac
done

case "$MODE" in
  up)
    if [ "$SUB" = "createChannel" ]; then
      networkUp
      createChannel
    else
      networkUp
    fi
    ;;
  createChannel)
    createChannel
    ;;
  down)
    networkDown
    ;;
  restart)
    networkDown "restart"
    networkUp
    ;;
  *)
    println "Usage: ./network.sh up | up createChannel | createChannel | down"
    exit 1
    ;;
esac
