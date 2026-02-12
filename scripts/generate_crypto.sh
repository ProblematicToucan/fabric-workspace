#!/usr/bin/env bash
# Generate crypto material for 1 orderer org + 1 peer org using cryptogen

WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}
. ${WORKSPACE_HOME}/scripts/utils.sh

if ! which cryptogen > /dev/null 2>&1; then
  fatalln "cryptogen not found. Add fabric-samples/bin to PATH."
fi

if [ -d "${WORKSPACE_HOME}/organizations/peerOrganizations" ]; then
  infoln "Removing existing crypto..."
  rm -Rf "${WORKSPACE_HOME}/organizations/peerOrganizations" "${WORKSPACE_HOME}/organizations/ordererOrganizations"
fi

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
