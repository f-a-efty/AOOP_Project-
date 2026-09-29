-- SQL Lab Deliverable: Reusable Views for Dashboard Metrics
USE greenify_db;

-- 1. Booth Status Summary View (Capacity, Fill %, Status)
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

-- 2. User Impact Summary View
CREATE OR REPLACE VIEW vw_user_impact_summary AS
SELECT 
    u.user_id,
    u.full_name,
    u.phone_number,
    u.total_tokens,
    u.wallet_balance,
    u.loyalty_level,
    COALESCE(SUM(d.plastic_weight_kg), 0.000) AS total_kg_recycled,
    COUNT(d.deposit_id) AS total_deposits_count,
    ROUND(COALESCE(SUM(d.plastic_weight_kg), 0.000) * 1.5, 2) AS estimated_co2_kg_prevented
FROM users u
LEFT JOIN plastic_deposits d ON u.user_id = d.user_id
WHERE u.role = 'USER'
GROUP BY u.user_id, u.full_name, u.phone_number, u.total_tokens, u.wallet_balance, u.loyalty_level;

-- 3. Company Operations View
CREATE OR REPLACE VIEW vw_company_operations_summary AS
SELECT 
    c.company_id,
    c.company_name,
    COUNT(DISTINCT b.booth_id) AS total_assigned_booths,
    COUNT(DISTINCT p.request_id) AS total_pickup_requests,
    COALESCE(SUM(col.net_weight_kg), 0.000) AS total_collected_kg
FROM recycling_companies c
LEFT JOIN smart_booths b ON c.company_id = b.company_id
LEFT JOIN pickup_requests p ON c.company_id = p.company_id
LEFT JOIN collections col ON c.company_id = col.company_id
GROUP BY c.company_id, c.company_name;
