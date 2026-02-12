# Create a channel from scratch

This guide creates a Fabric application channel in the playground and joins the orderer and peer to it.

## Prerequisites

- **Fabric binaries** in your `PATH`: `configtxgen`, `cryptogen`, `osnadmin`  
  (e.g. from `fabric/build/bin` or `fabric-samples/bin`)
- **Docker** (for orderer and peer)

## Step 1: Generate crypto

Generate MSP material for the orderer org and the Garamm peer org:

```bash
cd /path/to/fabric-workspace
chmod +x scripts/*.sh
./scripts/generate_crypto.sh
```

This uses `organizations/cryptogen/crypto-config.yaml` and writes to:

- `organizations/ordererOrganizations/example.com/`
- `organizations/peerOrganizations/garamm.dev/`

If you already have `organizations/peerOrganizations/garamm.dev/` from a previous run, this will overwrite it. To keep only the orderer org, you can run cryptogen with a config that has only `OrdererOrgs` and use a different output directory, then merge.

## Step 2: Start the network

Start the orderer and peer:

```bash
docker compose up -d
```

Wait a few seconds for the orderer to be ready (no system channel; it uses channel participation).

## Step 3: Create the channel genesis block

Generate the channel genesis block with the `MyChannel` profile from `configtx/configtx.yaml`:

```bash
./scripts/create_channel.sh
# or for a custom name: ./scripts/create_channel.sh mychannel
```

This creates `channel-artifacts/mychannel.block` (or `<name>.block`).

## Step 4: Join the orderer to the channel

Tell the orderer to join the channel (admin port 7053):

```bash
./scripts/join_orderer.sh
# or: ./scripts/join_orderer.sh mychannel
```

If the orderer is not on localhost, set:

```bash
ORDERER_HOST=your-orderer-host ./scripts/join_orderer.sh
```

## Step 5: Join the peer to the channel

The peer container has `channel-artifacts/` mounted at `/etc/hyperledger/channel-artifacts`. Join the peer to the channel:

```bash
./scripts/join_peer.sh
# or: ./scripts/join_peer.sh mychannel
```

## Verify

- **Orderer**: Channel should appear in orderer logs or via `osnadmin channel list`.
- **Peer**: From the peer container:
  ```bash
  docker exec peer0.garamm.dev peer channel list
  ```
  You should see the channel (e.g. `mychannel`).

## Summary

| Step | Command | What it does |
|------|---------|----------------|
| 1 | `./scripts/generate_crypto.sh` | Generates orderer + peer MSP under `organizations/` |
| 2 | `docker compose up -d` | Starts orderer (7050, 7053) and peer (7051) |
| 3 | `./scripts/create_channel.sh [name]` | Creates `channel-artifacts/<name>.block` |
| 4 | `./scripts/join_orderer.sh [name]` | Orderer joins the channel via osnadmin |
| 5 | `./scripts/join_peer.sh [name]` | Peer joins the channel using the genesis block |

Channel config is in **configtx/configtx.yaml** (profile `MyChannel`). To change orgs or orderer, edit that file and re-run step 3, then re-join orderer and peer as needed.
