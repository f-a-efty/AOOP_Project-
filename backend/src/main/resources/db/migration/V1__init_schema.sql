-- V1__init_schema.sql: Greenify 3NF Relational Database Schema
-- Compatible with MySQL 8.0+

CREATE TABLE IF NOT EXISTS system_config (
    config_key VARCHAR(64) PRIMARY KEY,
    config_value VARCHAR(255) NOT NULL,
    description VARCHAR(500),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    bkash_number VARCHAR(20) NULL,
    address TEXT,
    password_hash VARCHAR(255) NOT NULL,
    total_tokens INT NOT NULL DEFAULT 0 CHECK (total_tokens >= 0),
    wallet_balance DECIMAL(10,2) GENERATED ALWAYS AS (total_tokens / 4.0) STORED,
    loyalty_level VARCHAR(32) DEFAULT 'Eco Buddy',
    role ENUM('USER','COMPANY','ADMIN','BOOTH_DEVICE') NOT NULL DEFAULT 'USER',
    status ENUM('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_phone (phone_number),
    INDEX idx_user_role (role)
);

CREATE TABLE IF NOT EXISTS recycling_companies (
    company_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    registration_number VARCHAR(100) NOT NULL UNIQUE,
    permit_info TEXT,
    contact_email VARCHAR(100) NOT NULL UNIQUE,
    contact_phone VARCHAR(20) NOT NULL,
    contact_person_name VARCHAR(100),
    contact_person_phone VARCHAR(20),
    contact_person_email VARCHAR(100),
    company_address TEXT,
    region VARCHAR(100),
    status ENUM('PENDING','ACTIVE','REJECTED','SUSPENDED') NOT NULL DEFAULT 'PENDING',
    member_since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_company_status (status)
);

CREATE TABLE IF NOT EXISTS smart_booths (
    booth_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    booth_code VARCHAR(50) NOT NULL UNIQUE,
    company_id BIGINT NULL,
    location_address VARCHAR(255) NOT NULL,
    latitude DECIMAL(10,8) NULL,
    longitude DECIMAL(11,8) NULL,
    capacity_kg DECIMAL(8,3) NOT NULL DEFAULT 100.000 CHECK (capacity_kg > 0),
    current_weight_kg DECIMAL(8,3) NOT NULL DEFAULT 0.000 CHECK (current_weight_kg >= 0),
    booth_status VARCHAR(30) NOT NULL DEFAULT 'Empty',
    sensor_status VARCHAR(50) DEFAULT 'Online',
    last_pickup_date TIMESTAMP NULL,
    CONSTRAINT fk_booth_company FOREIGN KEY (company_id) REFERENCES recycling_companies(company_id) ON DELETE SET NULL,
    INDEX idx_booth_company (company_id),
    INDEX idx_booth_status (booth_status)
);

CREATE TABLE IF NOT EXISTS deposit_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    booth_id BIGINT NOT NULL,
    qr_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_session_booth FOREIGN KEY (booth_id) REFERENCES smart_booths(booth_id) ON DELETE CASCADE,
    INDEX idx_session_token (qr_token_hash)
);

CREATE TABLE IF NOT EXISTS plastic_deposits (
    deposit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    booth_id BIGINT NOT NULL,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    plastic_weight_kg DECIMAL(8,3) NOT NULL CHECK (plastic_weight_kg > 0),
    plastic_type VARCHAR(50) DEFAULT 'PET/Mix',
    tokens_earned INT NOT NULL CHECK (tokens_earned >= 0),
    rate_snapshot INT NOT NULL DEFAULT 100,
    deposit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_deposit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_deposit_booth FOREIGN KEY (booth_id) REFERENCES smart_booths(booth_id) ON DELETE CASCADE,
    CONSTRAINT fk_deposit_session FOREIGN KEY (session_id) REFERENCES deposit_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_deposit_user_date (user_id, deposit_timestamp),
    INDEX idx_deposit_booth (booth_id)
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    transaction_type VARCHAR(30) NOT NULL,
    tokens_delta INT NOT NULL,
    cash_delta DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    balance_after_tokens INT NOT NULL,
    bkash_trx_id VARCHAR(64) UNIQUE NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Completed',
    idempotency_key VARCHAR(128) UNIQUE NULL,
    transaction_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tx_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_tx_user_date (user_id, transaction_timestamp),
    INDEX idx_tx_status (status)
);

CREATE TABLE IF NOT EXISTS coupons (
    coupon_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL,
    promo_code VARCHAR(50) NOT NULL UNIQUE,
    discount_percentage INT NOT NULL CHECK (discount_percentage BETWEEN 1 AND 100),
    token_cost INT NOT NULL CHECK (token_cost > 0),
    quantity_available INT NOT NULL CHECK (quantity_available >= 0),
    expiry_date TIMESTAMP NOT NULL,
    terms_and_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_coupon_redemptions (
    redemption_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    coupon_id BIGINT NOT NULL,
    redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_redemption_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_redemption_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT NOT NULL,
    vehicle_number VARCHAR(50) NOT NULL UNIQUE,
    vehicle_type VARCHAR(50) NOT NULL,
    driver_name VARCHAR(100) NOT NULL,
    driver_phone VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_vehicle_company FOREIGN KEY (company_id) REFERENCES recycling_companies(company_id) ON DELETE CASCADE,
    INDEX idx_vehicle_company (company_id, status)
);

CREATE TABLE IF NOT EXISTS pickup_requests (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    request_code VARCHAR(50) NOT NULL UNIQUE,
    booth_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    vehicle_id BIGINT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    status VARCHAR(30) NOT NULL DEFAULT 'Pending',
    payload_kg_at_request DECIMAL(8,3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    CONSTRAINT fk_pickup_booth FOREIGN KEY (booth_id) REFERENCES smart_booths(booth_id) ON DELETE CASCADE,
    CONSTRAINT fk_pickup_company FOREIGN KEY (company_id) REFERENCES recycling_companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_pickup_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE SET NULL,
    INDEX idx_pickup_company_status (company_id, status, priority)
);

CREATE TABLE IF NOT EXISTS collections (
    collection_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pickup_request_id BIGINT NOT NULL,
    booth_id BIGINT NOT NULL,
    company_id BIGINT NOT NULL,
    net_weight_kg DECIMAL(8,3) NOT NULL,
    plastic_grade VARCHAR(50) DEFAULT 'PET 100% Sorted',
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coll_request FOREIGN KEY (pickup_request_id) REFERENCES pickup_requests(request_id) ON DELETE CASCADE,
    CONSTRAINT fk_coll_booth FOREIGN KEY (booth_id) REFERENCES smart_booths(booth_id) ON DELETE CASCADE,
    CONSTRAINT fk_coll_company FOREIGN KEY (company_id) REFERENCES recycling_companies(company_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS campaigns (
    campaign_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    type VARCHAR(50) NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS campaign_participants (
    participant_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    campaign_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_camp_part_campaign FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id) ON DELETE CASCADE,
    CONSTRAINT fk_camp_part_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_campaign_user UNIQUE (campaign_id, user_id)
);

CREATE TABLE IF NOT EXISTS loyalty_levels (
    level VARCHAR(32) PRIMARY KEY,
    min_kg DECIMAL(8,3) NOT NULL,
    max_kg DECIMAL(8,3) NOT NULL,
    benefits TEXT,
    badge VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS notifications (
    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recipient_role VARCHAR(20) NOT NULL,
    recipient_id BIGINT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(30) NOT NULL DEFAULT 'System',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_recipient (recipient_role, recipient_id, is_read)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    token_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rt_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS otp_codes (
    otp_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    code_hash VARCHAR(255) NOT NULL,
    purpose ENUM('REGISTER', 'RESET') NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    consumed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_otp_phone (phone_number, purpose)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    admin_id BIGINT NULL,
    admin_email VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    detail TEXT,
    module VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Database View required for DBMS Lab submission
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
