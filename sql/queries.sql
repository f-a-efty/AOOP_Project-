-- SQL Lab Deliverable: Queries Demonstrating Required Relational Features
USE greenify_db;

-- 1. Aggregation with GROUP BY / HAVING (Identifies users eligible for loyalty upgrade > 50 kg)
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

-- 2. INNER JOIN & LEFT JOIN (Booths with assigned companies, including idle/unassigned booths)
SELECT 
    b.booth_code,
    b.location_address,
    b.current_weight_kg,
    b.booth_status,
    COALESCE(c.company_name, 'UNASSIGNED') AS operating_company
FROM smart_booths b
LEFT JOIN recycling_companies c ON b.company_id = c.company_id
ORDER BY b.current_weight_kg DESC;

-- 3. Nested & Correlated Subquery (Users whose total cashback exceeds platform average payout)
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

-- 4. View Querying (Querying real-time booth status summary view)
SELECT * FROM vw_booth_status_summary
WHERE fill_percentage >= 80.00;
