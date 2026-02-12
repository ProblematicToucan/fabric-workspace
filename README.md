# Minimal Fabric Network (Learning)

One **orderer** and one **peer** (Org1). Good for understanding how Fabric nodes, channels, and genesis blocks work.

## Prerequisites

- **Docker** (and Docker Compose)
- **Fabric binaries**: `configtxgen`, `cryptogen`, `peer`, `osnadmin` must be on `PATH`.  
  Easiest: use the sibling `fabric-samples` repo; `network.sh` adds `../fabric-samples/bin` to `PATH` when you run from this directory.

If you don't have the binaries yet (from [Fabric docs](https://hyperledger-fabric.readthedocs.io/en/latest/install.html)):

```bash
cd ../fabric-samples
./scripts/fabric.sh binary
# or use the install-fabric.sh script from Fabric docs
```

## Quick start

From **fabric-workspace** root:

```bash
# 1. Bring up network and create a channel (crypto + containers + channel + peer join)
./network.sh up createChannel

# 2. Later: tear down (removes containers, volumes, crypto, channel artifacts)
./network.sh down
```

## Commands

| Command | What it does |
|--------|----------------|
| `./network.sh up` | Generate crypto (if missing), start **orderer** + **peer** containers |
| `./network.sh up createChannel` | Same as `up`, then create channel `mychannel` and join the peer |
| `./network.sh createChannel` | Create channel and join peer (network must already be up) |
| `./network.sh down` | Stop containers, remove volumes and generated crypto/artifacts |

Options (e.g. for createChannel):

- `-c <name>` — channel name (default: `mychannel`)
- `-d <sec>` — delay between retries (default: 3)
- `-r <n>` — max retries (default: 5)

## Layout (learning)

- **organizations/cryptogen/** — Cryptogen configs: one for orderer org, one for peer org (Org1). Generates certs under `organizations/ordererOrganizations/` and `organizations/peerOrganizations/`.
- **configtx/configtx.yaml** — Defines OrdererOrg, Org1, and the channel profile (ChannelUsingRaft). Used to generate the **channel genesis block**.
- **docker-compose.yaml** — One orderer service, one peer service (Org1), shared network.
- **scripts/generate_crypto.sh** — Runs cryptogen for both configs.
- **scripts/createChannel.sh** — (1) Generates genesis block with `configtxgen`, (2) joins orderer to channel with `osnadmin channel join`, (3) joins peer with `peer channel join`.
- **network.sh** — Entrypoint: crypto generation, `docker compose`, and channel creation.

## Ports

- Orderer: **7050** (orderer), **7053** (admin), **9443** (ops)
- Peer: **7051** (peer), **9444** (ops)

## Verify

After `./network.sh up createChannel`:

```bash
# Containers
docker ps

# Peer joined channel (run from fabric-workspace; PATH must include fabric-samples/bin)
export FABRIC_CFG_PATH=$PWD/peercfg
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer channel list
# Should list: mychannel
```
