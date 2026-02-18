# Asset Transfer Basic – TypeScript Chaincode

## Development workflow

### Build and lint

```bash
npm install
npm run build          # compile TypeScript → dist/
npm run build:watch    # compile on file changes
npm run lint           # ESLint (also runs before test)
```

### Do you need to deploy to see results?

**No, for logic and correctness:** you can unit test the contract with a **mock stub** (in-memory state) and never touch a Fabric network. Run `npm test` (see below).

**Yes, for end-to-end behavior:** to see results on a real ledger (transactions committed, queries against actual world state), you need either:

1. **Deploy to a network** – e.g. test-network: `./network.sh deployCC` or `./network.sh deployCCAAS` from `test-network/`, then invoke/query via peer or an app.
2. **Chaincode as a Service (CaaS)** – run the chaincode process yourself (or in Docker) and point the peer at it; good for **debugging** (see below).

So: use **unit tests** for fast iteration and CI; use **deploy/CaaS** when you need to verify against a real peer and ledger.

---

## Testing (no deploy required)

Unit tests use **Vitest** and a mock stub that implements `getState`, `putState`, `deleteState`, and `getStateByRange`. No peer or network is needed.

```bash
npm test
```

Tests live in `src/` next to the code (e.g. `assetTransfer.spec.ts`). They instantiate `AssetTransferContract`, create a mock `Context` with the mock stub, and call the contract methods directly.

### How the mock context works (and how to create or extend it)

You can’t run the chaincode “for real” without a Fabric peer and ledger. The **mock context** (`mockContext.ts`) replaces the real `Context` (and its `stub`) with an in-memory implementation so unit tests can run without any network.

**How to know what to implement**

1. **From your chaincode** – See which `ctx.stub` methods are used. For this contract, a quick search shows: `getState`, `putState`, `deleteState`, `getStateByRange`.
2. **From the API types** – The real types live in `node_modules`:
   - `fabric-contract-api/types/index.d.ts`: `Context` has `stub`, `clientIdentity`, `logging`.
   - `fabric-shim-api/types/index.d.ts`: `ChaincodeStub` defines the stub methods; `Iterators.KV` is `{ key, value }` (and optionally `namespace`). The chaincode uses `result.value.value` when iterating, so the mock must yield objects with a `value` property that has a `value` (the bytes).

**What the mock provides**

- **In-memory store** – A `Map<string, Uint8Array>` used by the stub so state survives across calls in a test.
- **Stub methods** – `getState` / `putState` / `deleteState` read/write/remove from that map. `getStateByRange(startKey, endKey)` returns an async iterator over keys in range (empty strings = open-ended); each `next()` returns `{ value: { key, value }, done }` so that `result.value.value` in the chaincode is the stored bytes.
- **Context shape** – `newMockContext()` returns an object with `stub`, `clientIdentity` (empty object), and `logging` (no-op). That’s enough for this contract; add more (e.g. `clientIdentity.getID()`) if a transaction uses it.
- **Reset** – `resetMockStubStore()` clears the map so each test can start from a clean state (used in `beforeEach`).

**If you add or change contract logic**

- If the contract uses a **new stub method** (e.g. `getQueryResult`, `getHistoryForKey`), add a matching implementation on the mock stub that reads/writes from the same in-memory store (or a separate structure for history) and returns the same iterator/result shape as in `fabric-shim-api`.
- If the contract uses **`ctx.clientIdentity`** (e.g. `getID()`, `getMSPID()`), extend the mock’s `clientIdentity` with those methods returning test values.
- Re-run `npm test` after changes; the types will still come from `fabric-contract-api` / `fabric-shim-api`, so the mock only needs to satisfy what the contract actually calls.

---

## Debugging

### 1. Node inspector (attach debugger)

The `start:server-debug` script runs the chaincode server with Node inspector (port 9229):

```bash
# From chaincode-typescript (with env set as the peer would pass)
export CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999
export CHAINCODE_ID=basic_1.0:placeholder
npm run start:server-debug
```

Then attach your IDE (VS Code / Cursor) to `localhost:9229` (or the container’s host if running in Docker). Ensure `sourceMap: true` in `tsconfig.json` (already set) so breakpoints match TypeScript.

### 2. Chaincode as a Service (CaaS) – recommended for “real” debugging

With CaaS you run the chaincode process yourself (or in a container you control), so you can start it under a debugger or with extra logging.

1. From `test-network/`:
   ```bash
   ./network.sh up createChannel -ca
   ./network.sh deployCCAAS -ccn basicts -ccp ../asset-transfer-basic/chaincode-typescript -ccaasdocker false
   ```
   This prints the `docker build` and `docker run` commands it would use; it does **not** start containers.

2. Build the image and run the container **manually**, with debug port and `-it`:
   ```bash
   docker build -f ../asset-transfer-basic/chaincode-typescript/Dockerfile -t basicts_ccaas_image:latest .
   docker run --rm -it -p 9229:9229 --name peer0org1_basicts_ccaas --network fabric_test \
     -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 \
     -e CHAINCODE_ID=<use the ID from deployCCAAS output> \
     -e CORE_CHAINCODE_ID_NAME=<same as above> \
     basicts_ccaas_image:latest
   ```
   Use the image/script that starts the process with `NODE_OPTIONS='--inspect=0.0.0.0:9229'` (e.g. `start:server-debug` in the Dockerfile), then attach your debugger to `localhost:9229`.

3. **Timeout:** If you single-step for a long time, increase the peer’s execute timeout (e.g. in `test-network/docker/compose-test-net.yaml`):
   ```yaml
   environment:
     CORE_CHAINCODE_EXECUTETIMEOUT: 300s
   ```

See `test-network/CHAINCODE_AS_A_SERVICE_TUTORIAL.md` for full CaaS and multi-peer details.

---

## Summary

| Goal                    | Approach                    | Deploy? |
|-------------------------|----------------------------|--------|
| Test business logic     | `npm test` (unit + mock)   | No     |
| Lint / typecheck        | `npm run lint`, `npm run build` | No  |
| Debug with breakpoints  | CaaS + `start:server-debug` + attach to 9229 | Yes (network up; you run chaincode) |
| E2E on real ledger      | `deployCC` or `deployCCAAS` + invoke/query | Yes    |
