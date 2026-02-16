#!/usr/bin/env bash
#
# =============================================================================
# add_org3_to_channel.sh — Channel config update to add Org3 (learning)
# =============================================================================
#
# LEARNING: Adding an org to a channel is a *channel config update*. The flow:
#   1. Fetch the current channel config (latest config block) from the orderer.
#   2. Decode it to JSON, add the new org's MSP definition under Application.
#   3. Compute the delta (configtxlator compute_update) and wrap it in an envelope.
#   4. Sign the update (existing org admin) and submit to the orderer.
#
# We use the *parent* Org1 identity to fetch, sign, and submit — only existing
# channel members can change the config. Prereqs: parent network up, channel
# created, Org3 crypto generated; jq and configtxlator on PATH.
#
# =============================================================================
set -e
THIRD_ROOT=$(cd "$(dirname "$0")/.." && pwd)
PARENT_ROOT="${THIRD_ROOT}/.."
CHANNEL_NAME="${1:-mychannel}"

export PATH="${PARENT_ROOT}/../fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${PARENT_ROOT}/peercfg"
export WORKSPACE_HOME="${PARENT_ROOT}"
. "${PARENT_ROOT}/scripts/envVar.sh"
. "${PARENT_ROOT}/scripts/utils.sh"

mkdir -p "${THIRD_ROOT}/channel-artifacts"

# -----------------------------------------------------------------------------
# Step 1 — Org definition for the channel
# configtxgen -printOrg writes the MSP + policies as JSON. It reads from
# FABRIC_CFG_PATH and expects a file named configtx.yaml there.
# -----------------------------------------------------------------------------
if [ ! -f "${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/org3.json" ]; then
  infoln "Generating Org3 organization definition..."
  FABRIC_CFG_PATH="${THIRD_ROOT}/configtx" configtxgen -printOrg Org3MSP > "${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/org3.json"
  verifyResult $? "configtxgen -printOrg Org3MSP failed"
fi

# -----------------------------------------------------------------------------
# Step 2 — Fetch current channel config
# peer channel fetch config retrieves the latest config block. We use Org1
# (parent) because only a member org can read the config. Orderer at 7050.
# -----------------------------------------------------------------------------
infoln "Fetching channel config for ${CHANNEL_NAME}..."
setGlobals
peer channel fetch config "${THIRD_ROOT}/channel-artifacts/config_block.pb" \
  -o localhost:7050 -c "${CHANNEL_NAME}" --tls --cafile "$ORDERER_CA" \
  >> "${THIRD_ROOT}/log.txt" 2>&1
verifyResult $? "Failed to fetch config block"

# Decode Block -> JSON and extract the Config (first envelope's config).
# config_block.json = full block; config.json = just the config for diffing.
configtxlator proto_decode --input "${THIRD_ROOT}/channel-artifacts/config_block.pb" \
  --type common.Block --output "${THIRD_ROOT}/channel-artifacts/config_block.json"
jq '.data.data[0].payload.data.config' "${THIRD_ROOT}/channel-artifacts/config_block.json" > "${THIRD_ROOT}/channel-artifacts/config.json"
verifyResult $? "Failed to extract config JSON (need jq)"

# -----------------------------------------------------------------------------
# Step 3 — Merge Org3 into Application groups
# We only add Org3MSP under Application.groups; other Application fields stay.
# (fabric-samples addOrg3 uses jq the same way: configUpdate.sh + updateChannelConfig.sh.)
# With -s, inputs are [config, org3]; bind both so .[1] is valid when modifying.
# -----------------------------------------------------------------------------
infoln "Adding Org3 to channel config..."
jq -s '.[0] as $config | .[1] as $org3 | $config | .channel_group.groups.Application.groups.Org3MSP = $org3' \
  "${THIRD_ROOT}/channel-artifacts/config.json" \
  "${THIRD_ROOT}/organizations/peerOrganizations/org3.example.com/org3.json" \
  > "${THIRD_ROOT}/channel-artifacts/modified_config.json"
verifyResult $? "jq merge failed"

# -----------------------------------------------------------------------------
# Step 4 — Compute config update and wrap in envelope
# configtxlator compute_update produces a ConfigUpdate (delta). The orderer
# expects an Envelope containing that delta (type 2 = CONFIG_UPDATE). We build
# the envelope JSON and encode it to .pb.
# -----------------------------------------------------------------------------
configtxlator proto_encode --input "${THIRD_ROOT}/channel-artifacts/config.json" \
  --type common.Config --output "${THIRD_ROOT}/channel-artifacts/original_config.pb"
configtxlator proto_encode --input "${THIRD_ROOT}/channel-artifacts/modified_config.json" \
  --type common.Config --output "${THIRD_ROOT}/channel-artifacts/modified_config.pb"
configtxlator compute_update --channel_id "${CHANNEL_NAME}" \
  --original "${THIRD_ROOT}/channel-artifacts/original_config.pb" \
  --updated "${THIRD_ROOT}/channel-artifacts/modified_config.pb" \
  --output "${THIRD_ROOT}/channel-artifacts/config_update.pb"
configtxlator proto_decode --input "${THIRD_ROOT}/channel-artifacts/config_update.pb" \
  --type common.ConfigUpdate --output "${THIRD_ROOT}/channel-artifacts/config_update.json"
# type 2 = CONFIG_UPDATE in channel header
echo '{"payload":{"header":{"channel_header":{"channel_id":"'"${CHANNEL_NAME}"'", "type":2}},"data":{"config_update":'$(cat "${THIRD_ROOT}/channel-artifacts/config_update.json")'}}}' | jq . > "${THIRD_ROOT}/channel-artifacts/config_update_in_envelope.json"
configtxlator proto_encode --input "${THIRD_ROOT}/channel-artifacts/config_update_in_envelope.json" \
  --type common.Envelope --output "${THIRD_ROOT}/channel-artifacts/org3_update_in_envelope.pb"

# -----------------------------------------------------------------------------
# Step 5 — Sign and submit
# Channel config updates require signatures from admins per channel policy
# (e.g. MAJORITY Admins). Here we have only Org1, so one signature suffices.
# peer channel update sends the signed envelope to the orderer.
# -----------------------------------------------------------------------------
infoln "Signing and submitting config update..."
peer channel signconfigtx -f "${THIRD_ROOT}/channel-artifacts/org3_update_in_envelope.pb"
peer channel update -f "${THIRD_ROOT}/channel-artifacts/org3_update_in_envelope.pb" \
  -c "${CHANNEL_NAME}" -o localhost:7050 --tls --cafile "$ORDERER_CA"
verifyResult $? "Failed to submit channel update"

successln "Org3 added to channel ${CHANNEL_NAME}"
