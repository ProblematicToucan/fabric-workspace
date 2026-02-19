# Farmer Supply Chain – Fabric Study Case

Supply chain between **Farmer**, **Logistics**, **Retail**, and **Network Manager**, with traceability and multi-party trust.

---

## Design: Real-world orgs vs blending

**Recommendation: one org per real-world entity (no blending).**

| Approach | Pros | Cons |
|----------|------|------|
| **1 org = 1 entity** (Network Manager, Farmer, Logistics, Retail) | Clear trust boundaries; each party has its own MSP and identity; matches how Fabric is used in production; easy to explain and audit | More orgs (e.g. 4) → more config and peers |
| **Blended orgs** (e.g. Farmer+NGO, Logistics+Retail in one org each) | Fewer orgs, simpler network for a study | Unclear who “owns” the MSP; less realistic; harder to add new parties later |

**When blending can be OK:** proof-of-concept, very small study, or when several actors are legally one consortium (e.g. one “Producers Co-op” MSP for many farmers). For a study case that mirrors real roles, **prefer 4 orgs: Network Manager, Farmer, Logistics, Retail.**

---

## ORGs (recommended: 4 organizations)

- **Org1 = NetworkManagerMSP** → Platform / technology provider — add/register new orgs only; no supply chain transactions
- **Org2 = FarmerMSP** → Producers (farms, cooperatives)
- **Org3 = LogisticsMSP** → Transport, warehouse, last-mile
- **Org4 = RetailMSP** → Shops, markets, sellers

*Alternative (simplified):* 3 orgs by merging Logistics+Retail into **SupplyChainMSP** if you want fewer peers for a minimal study.

---

## User types (roles)

- **networkAdmin** — Org1 (Network Manager)
- **farmer** — Org2
- **logisticsUser** — Org3
- **retailUser** — Org4

---

## Operations by org

### Org1 – NetworkManagerMSP (platform only)

- Add new org to the network (e.g. Org5, Org6, …)
- Register new org (governance only; no business ledger writes)

### Org2 – FarmerMSP

- RegisterProduce / RecordHarvest
- GetProduce / GetBatch
- TransferToLogistics (handoff to supply chain)

### Org3 – LogisticsMSP

- ReceiveFromProducer (accept batch from Farmer)
- RecordShipment / UpdateLocation
- DeliverToRetail (handoff to retail)
- GetShipment / GetShipmentsByBatch

### Org4 – RetailMSP

- ReceiveFromLogistics (accept delivery)
- RecordSale / GetBatchHistory
- GetAllBatches (traceability queries)

---

*Study case: 4 orgs — Network Manager, Farmer, Logistics, Retail (1 org per real-world entity).*
