# Charity NGO

Regulated + Compliant + Transparency

## ORGs

- Org1 = PlatformMSP -> Add new Org
- Org2 = GovMSP -> Register GovAdmin cert -> onboard Bank & government user
- Org3 = NGOMSP -> Register NGOAdmin -> Register NGO's

## User Types - user roles

- admin (platform) - org1
- govAdmin - org2
- govUser
- bankUser
- donor (public user)
- ngoAdmin - org3
- ngoUser

## Operation by org types

### Org1 - PlatformMSP - platform user

- add new org to the network ex: Org3, Org4, ...

### Org2 - GovMSP - government user

- RegisterDonor
- GetDonor
- GetAllDonors
- RegisterBank
- GetBank
- GetAllBanks
- GetAllNGOs
- GetAllDonationsByDonor

### Org2MSP - bank users

- Issue fund/token
- Transfer fund/token

### Org2MSP - donor users

- Donate
- GetAllFunds

### Org3 - NGOMSP - NGO user

- NGO user with adminUser role
  - RegisterNGO
  - GetNGO
- NGO user with ngoUser role
  - CreateFund
  - GetFund
  - CloseFund
  - AddExpense
  - GetAllFundsByNGO
  - ReedemFund

