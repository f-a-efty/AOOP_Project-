USE greenify_db;

DROP TABLE IF EXISTS audit_logs;

CREATE TABLE IF NOT EXISTS booth_qr_tokens (
    token_hash CHAR(64) PRIMARY KEY,
    booth_id BIGINT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    consumed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_qr_token_booth FOREIGN KEY (booth_id) REFERENCES smart_booths(booth_id) ON DELETE CASCADE,
    INDEX idx_qr_token_booth_expiry (booth_id, expires_at, consumed_at)
);

UPDATE smart_booths b
SET b.company_id = NULL
WHERE b.booth_code IN ('B-Gul-2', 'B-Ban-1')
    AND NOT EXISTS (
            SELECT 1 FROM pickup_requests p
            WHERE p.booth_id = b.booth_id
                AND p.status IN ('Pending', 'Accepted', 'Vehicle Assigned', 'On Pickup')
    );