-- V2__seed_data.sql: Seed Initial Operational Data for Greenify (Dhaka Context)

-- System Config Setup
INSERT INTO system_config (config_key, config_value, description) VALUES
('tokens_per_kg', '100', 'Number of reward tokens earned per 1 kg of plastic'),
('tokens_per_taka', '4', 'Conversion rate: 4 tokens equal 1 BDT taka'),
('min_withdrawal_taka', '100', 'Minimum withdrawal threshold in BDT taka (400 tokens)'),
('almost_full_threshold_pct', '80', 'Percentage fill level triggering Almost Full status and company notification'),
('co2_kg_per_plastic_kg', '1.5', 'Estimated kg of CO2 offset per 1 kg of plastic recycled'),
('qr_ttl_seconds', '60', 'Booth QR code validity period in seconds');

-- Loyalty Tiers
INSERT INTO loyalty_levels (level, min_kg, max_kg, benefits, badge) VALUES
('Eco Buddy', 0.000, 50.000, 'Basic coupon redemptions & community leaderboard entry', 'leaf_bronze'),
('Green Friend', 50.000, 150.000, 'Exclusive brand discounts & early campaign entry', 'leaf_silver'),
('Nature Hero', 150.000, 300.000, 'VIP partner vouchers & eco-champion digital badge', 'leaf_gold'),
('Nature Guardian', 300.000, 99999.000, 'Priority customer support & invitation to annual eco summit', 'leaf_diamond');

-- Initial Users (Password: Password123! -> BCrypt hash)
-- BCrypt for 'Password123!' is $2a$10$7R7z64a/H50F2K4QyqU1y.lZ29qH1hC3c1d9a0b1c2d3e4f5g6h7
INSERT INTO users (full_name, phone_number, bkash_number, address, password_hash, total_tokens, loyalty_level, role, status) VALUES
('System Administrator', '+8801700000000', '+8801700000000', 'Greenify HQ, Gulshan-2, Dhaka', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 0, 'Nature Guardian', 'ADMIN', 'ACTIVE'),
('Rakibul Islam', '+8801711111111', '+8801711111111', 'House 42, Road 7, Dhanmondi, Dhaka', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 450, 'Green Friend', 'USER', 'ACTIVE'),
('Tania Sultana', '+8801822222222', '+8801822222222', 'Block C, Section 10, Mirpur, Dhaka', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 150, 'Eco Buddy', 'USER', 'ACTIVE'),
('ABC Recycling Manager', '+8801933333333', '+8801933333333', 'Tejgaon Industrial Area, Dhaka', '$2a$10$8.UnVuG9HHgffUDAlk8qfOuVGkqRzgVymGe07xd00DMxs.AQubh4a', 0, 'Eco Buddy', 'COMPANY', 'ACTIVE');

-- Recycling Companies
INSERT INTO recycling_companies (company_name, registration_number, permit_info, contact_email, contact_phone, contact_person_name, contact_person_phone, contact_person_email, company_address, region, status) VALUES
('ABC Recycling Ltd.', 'REC-2024-9842', 'DOE Permit #8849-2024 (Class A Hazardous/Plastic Processing)', 'contact@abcrecycling.bd', '+8801933333333', 'Mahmud Hasan', '+8801933333333', 'mahmud@abcrecycling.bd', 'Plot 14, Tejgaon I/A, Dhaka-1208', 'Dhaka Central', 'ACTIVE'),
('Bengal Eco Solutions', 'REC-2024-4112', 'DOE Permit #7712-2024', 'info@bengaleco.com', '+8801644444444', 'Sabbir Ahmed', '+8801644444444', 'sabbir@bengaleco.com', 'Kachukhet Main Road, Dhaka', 'Dhaka North', 'PENDING');

-- Smart Collection Booths in Dhaka
INSERT INTO smart_booths (booth_code, company_id, location_address, latitude, longitude, capacity_kg, current_weight_kg, booth_status, sensor_status) VALUES
('BTH-DH-001', 1, 'Dhanmondi Lake Park Entrance, Road 8, Dhaka', 23.74610000, 90.37420000, 100.000, 25.500, 'Available', 'Online'),
('BTH-DH-002', 1, 'Mirpur 10 Bus Stand Roundabout, Dhaka', 23.80690000, 90.36870000, 100.000, 82.000, 'Almost Full', 'Online'),
('BTH-DH-003', 1, 'Uttara Sector 3 Park, Road 4, Dhaka', 23.86900000, 90.39800000, 100.000, 100.000, 'Full', 'Online'),
('BTH-DH-004', 1, 'Gulshan 2 DCC Market Plaza, Dhaka', 23.79480000, 90.41430000, 150.000, 12.000, 'Available', 'Online'),
('BTH-DH-005', 1, 'Banani Chairman Bari Bus Stop, Dhaka', 23.79370000, 90.40470000, 100.000, 0.000, 'Empty', 'Online'),
('BTH-DH-006', NULL, 'Mohammadpur Town Hall Market, Dhaka', 23.75880000, 90.36300000, 100.000, 0.000, 'Under Maintenance', 'Sensor Error');

-- Vehicles
INSERT INTO vehicles (company_id, vehicle_number, vehicle_type, driver_name, driver_phone, status) VALUES
(1, 'DHAKA-METRO-HA-11-2041', '3-Ton Cover Van', 'Karim Ullah', '+8801755555555', 'Available'),
(1, 'DHAKA-METRO-HA-14-8890', '1.5-Ton Mini Truck', 'Jamal Hossain', '+8801866666666', 'Available');

-- Initial Pickup Requests
INSERT INTO pickup_requests (request_code, booth_id, company_id, priority, status, payload_kg_at_request) VALUES
('REQ-DH-8012', 3, 1, 'HIGH', 'Pending', 100.000),
('REQ-DH-8013', 2, 1, 'NORMAL', 'Pending', 82.000);

-- Initial Coupons
INSERT INTO coupons (brand_name, promo_code, discount_percentage, token_cost, quantity_available, expiry_date, terms_and_conditions) VALUES
('Aarong', 'AARONG-GREEN-15', 15, 200, 100, '2026-12-31 23:59:59', 'Valid on all Aarong lifestyle products online & in outlet. Min purchase ৳1000.'),
('Shwapno', 'SHWAPNO-ECO-100', 10, 150, 250, '2026-12-31 23:59:59', 'Valid for fresh produce and groceries at any Shwapno outlet.'),
('Agora Superstore', 'AGORA-PLASTIC-20', 20, 300, 50, '2026-11-30 23:59:59', 'Valid for reusable bag & sustainable product lines.');

-- Initial Campaigns
INSERT INTO campaigns (title, type, description, start_date, end_date, status) VALUES
('Dhaka Eco Challenge 2026', 'Recycling Challenge', 'Recycle over 10 kg plastic this month and earn an exclusive Nature Hero badge!', '2026-09-01 00:00:00', '2026-09-30 23:59:59', 'Active'),
('Gulshan Lake Cleanup Drive', 'Clean-up Event', 'Join community volunteers in cleaning plastic waste around Gulshan Lake Park.', '2026-10-05 08:00:00', '2026-10-05 18:00:00', 'Upcoming');
