# GREENIFY: bKash PAYOUT GATEWAY INTEGRATION SPECIFICATION

## Overview
Greenify enables plastic recyclers in Bangladesh to withdraw earned Tokens directly into cash via **bKash**. 
Conversion rate: **4 Tokens = ৳1.00 BDT**, minimum withdrawal **৳100.00 BDT** (400 Tokens).

---

## Technical Architecture (`PayoutGateway`)

```
                          +-------------------------+
                          |   WalletService         |
                          +------------+------------+
                                       |
                                       v
                          +-------------------------+
                          |   PayoutGateway         |
                          |   <<interface>>         |
                          +------------+------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
                   v                                       v
    +------------------------------+        +------------------------------+
    |     MockPayoutGateway        |        |    BkashPayoutGateway        |
    | (Default dev/demo provider)  |        |  (Production B2C adapter)    |
    +------------------------------+        +------------------------------+
```

---

## Provider Configuration
Set via `application.yml` or environment variables:
- `payout.provider=mock`: Default active provider. Simulates instant approval and includes magic failure number (`...999`) for testing debit rollback.
- `payout.provider=bkash`: Production bKash B2C API provider.

---

## Production Onboarding Requirements for bKash Disbursement API
1. **Merchant Onboarding**: Corporate bKash Merchant Account with B2C Disbursement permission.
2. **API Credentials**:
   - `BKASH_BASE_URL` (Sandbox: `https://checkout.sandbox.bka.sh/v1.2.0-beta`)
   - `BKASH_APP_KEY`
   - `BKASH_APP_SECRET`
   - `BKASH_USERNAME`
   - `BKASH_PASSWORD`
3. **Ip Whitelisting**: Server static IP must be registered with bKash security operations center.
