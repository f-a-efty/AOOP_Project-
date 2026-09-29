-- V3__update_admin.sql: Update admin credentials
UPDATE users SET phone_number = '+8801746995650', bkash_number = '+8801746995650', password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL56lkp.' WHERE role = 'ADMIN';
