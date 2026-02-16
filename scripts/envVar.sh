#!/usr/bin/env bash
#
# =============================================================================
# envVar.sh — Peer/orderer environment for single-org network (Org1)
# =============================================================================
#
# Sets CORE_PEER_* and ORDERER_CA so the peer CLI and createChannel scripts
# can talk to peer0.org1.example.com and the orderer. Sourced by
# createChannel.sh and by hand when running peer channel list / invoke / query.
#
# Usage: . scripts/envVar.sh  then call setGlobals before peer commands
# =============================================================================

WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}
. ${WORKSPACE_HOME}/scripts/utils.sh

# TLS: use TLS for peer and orderer connections
export CORE_PEER_TLS_ENABLED=true
# Orderer TLS CA cert (for channel create/update and deliver)
export ORDERER_CA=${WORKSPACE_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
# Org1 peer TLS CA cert (for peer connection)
export PEER0_ORG1_CA=${WORKSPACE_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

# -----------------------------------------------------------------------------
# setGlobals — Configure env for Org1 admin talking to peer0.org1.example.com
# Call once before running peer channel / chaincode commands.
# -----------------------------------------------------------------------------
setGlobals() {
  infoln "Using organization Org1"
  export CORE_PEER_LOCALMSPID=Org1MSP
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${WORKSPACE_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

# -----------------------------------------------------------------------------
# verifyResult — Exit with fatalln if previous command failed
# Args: $1 = exit code, $2 = error message
# -----------------------------------------------------------------------------
verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
