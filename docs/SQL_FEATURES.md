# GREENIFY: DBMS LAB SQL FEATURE COVERAGE (CSE 3522)

This document details the exact SQL feature coverage implemented in Greenify's MySQL 8 relational database as required for the CSE 3522 DBMS Lab project deliverables.

---

## 1. DML (Data Manipulation Language)
- **CRUD Operations**: Performed across all entities (`users`, `recycling_companies`, `smart_booths`, `plastic_deposits`, `wallet_transactions`, `coupons`, `pickup_requests`, `vehicles`, `collections`).
- **Location in Codebase**:
  - Insert deposit: `PlasticDepositRepository`, `DepositService.java`
  - Update booth status: `SmartBoothRepository`, `DepositService.java`
  - Credit wallet: `UserRepository`, `WalletService.java`

---

## 2. Aggregation with `GROUP BY` and `HAVING`
- **Query Specification**: Calculates total plastic recycled per user and filters users exceeding 50.0 kg for loyalty tier promotion to "Green Friend".
- **SQL Code**:
```sql
SELECT 
    u.user_id,
    u.full_name,
    COUNT(d.deposit_id) AS deposit_count,
    SUM(d.plastic_weight_kg) AS total_weight_kg,
    AVG(d.plastic_weight_kg) AS avg_weight_per_deposit_kg
FROM users u
INNER JOIN plastic_deposits d ON u.user_id = d.user_id
GROUP BY u.user_id, u.full_name
HAVING SUM(d.plastic_weight_kg) >= 50.000;
```
- **Location in Codebase**: `sql/queries.sql` and `PlasticDepositRepository.java`.

---

## 3. Joins (`INNER JOIN` and `LEFT JOIN`)
- **Query Specification**: Combines booth details with assigned recycling companies, preserving unassigned or idle booths using `LEFT JOIN`.
- **SQL Code**:
```sql
SELECT 
    b.booth_code,
    b.location_address,
    b.current_weight_kg,
    b.booth_status,
    COALESCE(c.company_name, 'UNASSIGNED') AS operating_company
FROM smart_booths b
LEFT JOIN recycling_companies c ON b.company_id = c.company_id
ORDER BY b.current_weight_kg DESC;
```
- **Location in Codebase**: `sql/queries.sql` and `vw_booth_status_summary`.

---

## 4. Subqueries (Nested and Correlated)
- **Query Specification**: Identifies top eco-citizens whose lifetime tokens exceed the platform average.
- **SQL Code**:
```sql
SELECT 
    u.user_id,
    u.full_name,
    u.total_tokens,
    u.wallet_balance
FROM users u
WHERE u.role = 'USER'
  AND u.total_tokens > (
      SELECT AVG(user_total_tokens)
      FROM (
          SELECT SUM(tokens_earned) AS user_total_tokens
          FROM plastic_deposits
          GROUP BY user_id
      ) AS user_totals
  );
```
- **Location in Codebase**: `sql/queries.sql`.

---

## 5. Reusable Views
- **View Definition (`vw_booth_status_summary`)**: Real-time capacity utilization and status dashboard.
- **SQL Code**:
```sql
CREATE OR REPLACE VIEW vw_booth_status_summary AS
SELECT 
    b.booth_id,
    b.booth_code,
    b.location_address,
    b.capacity_kg,
    b.current_weight_kg,
    ROUND((b.current_weight_kg / b.capacity_kg) * 100, 2) AS fill_percentage,
    b.booth_status,
    c.company_name AS assigned_company_name,
    b.last_pickup_date
FROM smart_booths b
LEFT JOIN recycling_companies c ON b.company_id = c.company_id;
```
- **Location in Codebase**: `sql/views.sql` and `V1__init_schema.sql`.

---

## 6. ACID Transactions & Row Locking
- **Transaction Flow**: bKash Token Cashout with Payout Rollback.
  - Step 1: Locks user row with `SELECT ... FOR UPDATE`.
  - Step 2: Checks token balance against requested withdrawal.
  - Step 3: Writes `Pending` ledger row and debits tokens.
  - Step 4: Calls `PayoutGateway`. On failure, rolls back token debit and marks status `Failed`.
- **Location in Codebase**: `WalletService.java`, `@Transactional` methods with `findByIdWithLock()`.

---

## 7. Indexes & Performance Tuning
1. `idx_deposit_user_date ON plastic_deposits(user_id, deposit_timestamp)`: Optimizes user recycling history queries.
2. `idx_tx_user_date ON wallet_transactions(user_id, transaction_timestamp)`: Fast wallet balance reconciliation.
3. `idx_pickup_company_status ON pickup_requests(company_id, status, priority)`: Fast priority queue filtering for recycling companies.
