# Third-org-server — Add a new org (Org3) to an existing channel

This directory is a **self-contained playground** for learning how to add a new organization (orderer and peer) when you already have an orderer and peer running with a channel. **Nothing here changes the parent `network.sh` or main config**; all scripts and config live under `third-org-server/`.

## What this does

- Adds a **new peer organization (Org3)** to the existing channel.
- The existing **orderer** stays the single orderer for the channel; we do not add a second orderer org in this playground (you can extend it later).
- You will:
  1. Generate Org3 crypto (in this directory).
  2. Run a **channel config update** to add Org3 to the channel (using parent’s Org1 identity and orderer).
  3. Start **peer0.org3** in a container that joins the same Docker network as the parent.
  4. **Join** peer0.org3 to the channel.

## Prerequisites

- Parent network is up and channel created, e.g. from `fabric-workspace`:
  ```bash
  cd /path/to/fabric-workspace
  ./network.sh up createChannel
  ```
- Fabric binaries on `PATH`: `configtxgen`, `configtxlator`, `cryptogen`, `peer` (e.g. from `fabric-samples/bin`).
- `jq` installed (for config update script).
- Docker (or Podman) and compose; same as parent.

## Steps (learning flow)

All commands are run from **`fabric-workspace/third-org-server`**.

### 1. Generate Org3 crypto

```bash
./run.sh generate
```

This creates `organizations/peerOrganizations/org3.example.com/` (one peer, one user) using `organizations/cryptogen/crypto-config-org3.yaml`. No changes to parent.

### 2. Add Org3 to the channel (config update)

```bash
./run.sh add-org
# Or for a specific channel: ./run.sh add-org mychannel
```

This script:

- Uses the **parent** Org1 identity to fetch the current channel config from the **existing orderer** (localhost:7050).
- Decodes the config, adds Org3’s MSP (from `configtx/configtx-org3.yaml` and `org3.json`) to the Application group.
- Builds a config update transaction, signs it as Org1, and submits it to the orderer.

After this, the channel’s application config includes Org3; no change to parent scripts or compose.

### 3. Start the Org3 peer

```bash
./run.sh up
```

This starts **peer0.org3** with:

- Crypto from `third-org-server/organizations/...`
- Same Docker network as the parent (`fabric_workspace`), so it can talk to the orderer and peer0.org1.
- Port **8051** on the host (so it doesn’t clash with peer0.org1 on 7051).

### 4. Join peer0.org3 to the channel

```bash
./run.sh join
# Or: ./run.sh join mychannel
```

This fetches the channel genesis block (using Org1 from the parent) and then runs `peer channel join` as **Org3** against the peer on 8051.

### 5. Optional: use Org3 from the host

From `third-org-server`, after `direnv allow` or sourcing `.envrc`:

```bash
peer channel list
peer channel getinfo -c mychannel
```

These use `CORE_PEER_*` for Org3 and `localhost:8051`.

### 6. Tear down only Org3

```bash
./run.sh down
```

This stops and removes the Org3 peer container only. Parent network and channel are unchanged.

## Layout (all under `third-org-server/`)

- `organizations/cryptogen/crypto-config-org3.yaml` — cryptogen spec for Org3.
- `organizations/peerOrganizations/org3.example.com/` — generated crypto and `org3.json` (from configtxgen -printOrg).
- `configtx/configtx-org3.yaml` — Org3 MSP definition for `configtxgen -printOrg Org3MSP`.
- `scripts/generate_org3_crypto.sh` — generate Org3 identities.
- `scripts/add_org3_to_channel.sh` — fetch config, add Org3, sign and submit (uses parent Org1 + orderer).
- `scripts/join_peer_org3.sh` — join peer0.org3 to the channel.
- `docker-compose.yaml` — single service: peer0.org3, network `fabric_workspace`, port 8051.
- `run.sh` — entrypoint: generate | add-org | up | join | down.
- `.envrc` — env for using peer CLI as Org3 (optional).

## Adding a new orderer (learning extension)

This playground adds only a **new peer org**. To add a **new orderer** (e.g. a second Raft node):

- You would add a new orderer org (or another orderer in the same org) and then perform a **channel config update** that changes the Orderer section (e.g. `Orderer.Addresses` and `EtcdRaft.Consenters`), then restart orderers. That flow is not implemented here so the playground stays focused on “add new org (peer).”

You can reuse the same pattern: keep a separate directory and scripts that call the parent orderer and existing identities, and only add your new orderer definition and config update logic.
