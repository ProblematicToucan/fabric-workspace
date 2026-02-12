#!/usr/bin/env bash
# Generate MSP crypto for orderer and peer orgs using cryptogen.
# Run from fabric-workspace root. Requires cryptogen in PATH (e.g. fabric/build/bin).

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Generating crypto with cryptogen..."
cryptogen generate --config="${ROOT}/organizations/cryptogen/crypto-config.yaml" --output="${ROOT}/organizations"

echo "Crypto written to:"
echo "  - organizations/ordererOrganizations/example.com"
echo "  - organizations/peerOrganizations/garamm.dev"
