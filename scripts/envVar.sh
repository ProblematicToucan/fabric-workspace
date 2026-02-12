#!/usr/bin/env bash
# Env for single org (Org1) + orderer — used by createChannel and peer CLI

WORKSPACE_HOME=${WORKSPACE_HOME:-${PWD}}
. ${WORKSPACE_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${WORKSPACE_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${WORKSPACE_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem

# Set env for the peer org (we only have Org1)
setGlobals() {
  infoln "Using organization Org1"
  export CORE_PEER_LOCALMSPID=Org1MSP
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${WORKSPACE_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
